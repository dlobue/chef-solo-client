
require 'fileutils'
require 'pathname'
require 'moneta/basic_file'

begin
    require 'fog'
    FOGFOUND = true unless defined? FOGFOUND
rescue LoadError => e
    Chef::Log.warn("Fog library not found. This is fine in development environments, but it is required in production.")
    FOGFOUND = false unless defined? FOGFOUND
end


class Chef::Resource::File
    def checksum(arg=nil)
      set_or_return(
        :checksum,
        arg,
        :regex => /^[a-zA-Z0-9]{32,64}$/
      )
    end
end

class Chef::Resource
  class S3File < Chef::Resource::RemoteFile

    def initialize(name, run_context=nil)
      super
      if not FOGFOUND
        raise RequirementError, "Aborting: The fog library is missing!"
      end
      @resource_name = :s3_file
      @provider = Chef::Provider::S3File
      @allowed_actions.push(:create_artifact)
      @download_threads = 10
      @bucket = nil
      @folder = nil
      @artifact = name
      #@artifact = File.basename(name, File.extname(name)) #turns /a/b/artifact_name.war into artifact_name
      @key_format = /.+-[^-]+\.(t(ar\.)?)?(gz|bz2)/
    end

    def download_threads(arg=nil)
      set_or_return(
        :download_threads,
        arg,
        :kind_of => [ Fixnum, FalseClass ]
      )
    end

    def bucket(arg=nil)
      set_or_return(
        :bucket,
        arg,
        :kind_of => [ String ]
      )
    end

    def folder(arg=nil)
      set_or_return(
        :folder,
        arg,
        :kind_of => [ String, NilClass ]
      )
    end

    def key_format(arg=nil)
      set_or_return(
        :key_format,
        arg,
        :kind_of => Regexp
      )
    end

    def artifact(arg=nil)
      set_or_return(
        :artifact,
        arg,
        :kind_of => String
      )
    end

    def provider(arg=nil)
      Chef::Resource.instance_method(:provider).bind(self).call(arg)
    end

  end
end

# release version of moneta has bug that doesn't return data value
class Moneta::BasicFile
  def [](key)
    if ::File.exist?(path(key))
      data = raw_get(key)
      if @expires
        if data[:expires_at].nil? || data[:expires_at] > Time.now
          data[:value]
        else
          delete!(key)
        end
      else
        data
      end
    end
  end
end

class Chef::ChecksumCache
  def generate_md5_checksum_for_file(file)
    key = generate_key(file)
    fstat = File.stat(file)
    lookup_result = lookup_checksum(key, fstat)
    return lookup_result if lookup_result


    checksum = checksum_file(file, Digest::MD5.new)
    moneta.store(key, {"mtime" => fstat.mtime.to_f, "checksum" => checksum})
    validate_checksum(key)
    checksum
  end
end

class DownloadError < RuntimeError
end

class Chef::Provider
  class S3File < Chef::Provider::RemoteFile

    def checksum(file)
      Chef::ChecksumCache.generate_md5_checksum_for_file(file)
    end

    def action_create
      bucket = get_bucket
      _action_create(bucket)
    end

    def action_create_artifact
      prefix = [@new_resource.folder, @new_resource.artifact].select { |x|
        not (x.nil? or x.empty?)
      }.join('/')

      bucket = get_bucket
      # First, see if there is a new archive to download.
      artifacts = bucket.files.all(
          :prefix => prefix
      ).to_a.select{ |k|
          not k.key.split('/')[-1].match(@new_resource.key_format).nil?
      }.sort { |a,b| b.key <=> a.key }

      raise "no artifacts found!" if artifacts.empty?

      Chef::Log.info("Newest artifact found is #{artifacts[0].key}")

      @new_resource.source(artifacts[0].key)

      _action_create(bucket)
    end

    def get_bucket
      storage = Fog::Storage.new(get_creds().merge(:provider => 'AWS'))
      storage.directories.get(@new_resource.bucket)
    end

    def _action_create(bucket)
      assert_enclosing_directory_exists!

      Chef::Log.debug("#{@new_resource} checking for changes")

      if current_resource_matches_target_checksum?
        Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
      else

        remote_file = bucket.files.head(@new_resource.source)

        if same_as_current_file?(remote_file)
          Chef::Log.debug "#{@new_resource} target and source are the same - not updating"
        else
          backup_new_resource
          begin
            if (remote_file.content_length / 1024 / 1024) <= 100 or @new_resource.download_threads == false
              ::File.open(@new_resource.path, 'w') do |local_file|
                remote_file.collection.get(remote_file.identity) do |chunk, remaining, total|
                  local_file.write(chunk)
                end
              end
            else
              def downloader(bytes_begin, bytes_end, remote_file)
                curthread = Thread.current
                curthread[:bytes_begin] = bytes_begin
                curthread[:bytes_end] = bytes_end

                ::File.open(@new_resource.path, 'r+') do |local_file|
                  local_file.pos = bytes_begin
                  begin
                    remote_file.collection.get(remote_file.identity,
                                               "Range" => "bytes=%d-%d" % [bytes_begin, bytes_end]
                                              ) do |chunk, remaining, total|
                      local_file.write(chunk)
                    end
                  rescue => e
                    curthread[:final_pos] = local_file.pos
                    raise e
                  end
                  curthread[:final_pos] = local_file.pos
                end
              end
              def spinner(threads)
                #so we don't have to wait until every thread finishes to find out an exception occurred
                sleep(5) until threads.map { |t| t.join(0.1) }.select { |t| t.nil? }.empty?
              end
              FileUtils.touch @new_resource.path
              threads = []
              num_parts = @new_resource.download_threads
              size = remote_file.content_length
              part_size = (size.to_f / num_parts.to_f).ceil
              Chef::Log.info "Remote file size: %s. Downloading %s parts %s large" % [size, num_parts, part_size]
              #TODO: change log level from info to debug when sure it works right
              num_parts.times do |i|
                bytes_begin = part_size * i
                bytes_end = [bytes_begin + part_size - 1, size - 1].min
                Chef::Log.info "Beginning downloading of part %s. Bytes beginning at %s and ending at %s" % [i, bytes_begin, bytes_end]
                #TODO: change log level from info to debug when sure it works right
                threads << Thread.new(bytes_begin, bytes_end) do |bytes_begin, bytes_end|
                  downloader(bytes_begin, bytes_end, remote_file)
                end
              end
              spinner(threads)
              raise DownloadError, "Some download threads are still alive!!" unless threads.select { |t| t.alive? }.empty?
              raise DownloadError, "Some download threads didn't finish downloading!" unless threads.reject { |t| t[:final_pos] == t[:bytes_end] }.empty?
              #TODO: retry downloading parts that failed
            end
          rescue => e
              ::File.delete( @new_resource.path ) if ::File.exists?( @new_resource.path )
              raise e
          end
          FileUtils.touch @new_resource.path
          @current_resource.checksum(checksum(@current_resource.path)) if ::File.exist?(@current_resource.path)
          if current_resource_matches_target_checksum? or same_as_current_file?(remote_file)
            Chef::Log.info "#{@new_resource} updated"
            @new_resource.updated_by_last_action(true)
          else
            Chef::Log.info "#{@new_resource} didn't download correctly"
            ::File.delete( @new_resource.path ) if ::File.exists?( @new_resource.path )
            raise DownloadError, "downloaded file does not match expectations!"
          end
        end
      end
      enforce_ownership_and_permissions

      @new_resource.updated_by_last_action?
    end

    def same_as_current_file?(candidate_file)
      Chef::Log.debug "#{@new_resource} checking for file existence of #{@new_resource.path}"
      if ::File.exists?(@new_resource.path)
        Chef::Log.debug "#{@new_resource} file exists at #{@new_resource.path}"

        if candidate_file.etag.include?('-')
          Chef::Log.debug("candidate_file's etag is not a valid md5sum. checking for md5sum in metadata")
          if candidate_file.metadata.has_key? "x-amz-meta-md5sum"
            chksum = candidate_file.metadata["x-amz-meta-md5sum"]
          else
            Chef::Log.debug("candidate_file's metadata is missing md5sum. consider adding it.")
            Chef::Log.debug("using filesize and timestamp to determine if remote file has changed.")
            return ( candidate_file.content_length == ::File.size(@new_resource.path) and \
              candidate_file.last_modified < ::File.mtime(@new_resource.path) )
          end
        else
          chksum = candidate_file.etag
        end

        @new_resource.checksum(chksum)

        Chef::Log.debug "#{@new_resource} target checksum: #{@current_resource.checksum}"
        Chef::Log.debug "#{@new_resource} source checksum: #{@new_resource.checksum}"

        @new_resource.checksum == @current_resource.checksum
      else
        Chef::Log.debug "#{@new_resource} creating #{@new_resource.path}"
        false
      end
    end

  end
end


Chef::Platform.platforms[:default].merge! :s3_file => Chef::Provider::S3File

