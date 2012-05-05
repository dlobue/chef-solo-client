
require 'fileutils'

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
  class S3RemoteFile < Chef::Resource::RemoteFile

    def initialize(name, run_context=nil)
      super
      if not FOGFOUND
        raise RequirementError, "Aborting: The fog library is missing!"
      end
      @resource_name = :s3_file
      @provider = Chef::Provider::S3RemoteFile
      @bucket = nil
    end

    def bucket(arg=nil)
      set_or_return(
        :bucket,
        arg,
        :kind_of => [ String ]
      )
    end

    def provider(arg=nil)
      Chef::Resource.instance_method(:provider).bind(self).call(arg)
    end

  end
end

class Chef::Resource
  class S3Artifact < Chef::Resource::S3RemoteFile

    def initialize(name, run_context=nil)
      super
      @resource_name = :s3_artifact
      @provider = Chef::Provider::S3Artifact
      @artifact = nil
      @folder = nil
      @key_format = /.+-[^-]+\.(t(ar\.)?)?(gz|bz2)/

      #these are for the untar action
      @allowed_actions.push(:untar, :download_and_untar)
      @delete_dir_in_container = nil
      @creates = nil
      @container_path = nil
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

    def folder(arg=nil)
      set_or_return(
        :folder,
        arg,
        :kind_of => [ String, NilClass ]
      )
    end

    def container_path(arg=nil)
      set_or_return(
        :container_path,
        arg,
        :kind_of => [ String, Pathname ]
      )
    end

    def creates(arg=nil)
      set_or_return(
        :creates,
        arg,
        :kind_of => [ String, Pathname ]
      )
    end

    def delete_dir_in_container(arg=nil)
      set_or_return(
        :delete_dir_in_container,
        arg,
        :kind_of => [ String, NilClass ]
      )
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


class Chef::Provider
  class S3RemoteFile < Chef::Provider::RemoteFile

    def checksum(file)
      Chef::ChecksumCache.generate_md5_checksum_for_file(file)
    end

    def action_create
      bucket = get_bucket
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

        #storage = Fog::Storage.new(get_creds().merge(:provider => 'AWS'))
        #bucket = storage.directories.get(@new_resource.bucket)

        remote_file = bucket.files.head(@new_resource.source)

        if same_as_current_file?(remote_file)
          Chef::Log.debug "#{@new_resource} target and source are the same - not updating"
        else
          backup_new_resource
          begin
              ::File.open(@new_resource.path, 'w') do |local_file|
                remote_file.collection.get(remote_file.identity) do |chunk, remaining, total|
                  local_file.write(chunk)
                end
              end
          rescue => e
              ::File.delete( @new_resource.path )
              raise e
          end
          FileUtils.touch @new_resource.path
          Chef::Log.info "#{@new_resource} updated"
          @new_resource.updated_by_last_action(true)
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

class Chef::Provider
  class S3Artifact < Chef::Provider::S3RemoteFile
    def action_download_and_untar
        action_create
        action_untar
    end

    def action_create
      prefix = [@new_resource.folder, @new_resource.artifact].select {|x| not (x.nil? or x.empty?)}.join('/')

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

    def action_untar

      raise "artifact archive missing!" unless ::File.exist? @new_resource.path

      createsPath = new_resource.creates.to_s.start_with?('/') ? new_resource.creates.to_s : ::File.join(new_resource.container_path, new_resource.creates)

      #extract block
      if not ::File.exists?(createsPath) or ::File.mtime(@new_resource.path) > ::File.mtime(createsPath)
          #delete block
          if not new_resource.delete_dir_in_container.nil?
              Chef::Log.info("deleting dir_in_container: #{new_resource.container_path}/#{new_resource.delete_dir_in_container}")
              FileUtils.remove_dir( "#{new_resource.container_path}/#{new_resource.delete_dir_in_container}", true )
          end
          Chef::Log.info("untaring archive #{@new_resource.path} to #{new_resource.container_path}")

          decompressvar = case
                          when @new_resource.path.end_with?('bz2') then 'j'
                          when @new_resource.path.end_with?('gz') then 'z'
                          else ''
                          end

          args = {:command => "tar #{decompressvar}xf #{@new_resource.path} -C #{new_resource.container_path}"}
          args[:user] = @new_resource.owner if @new_resource.owner
          args[:group] = @new_resource.group if @new_resource.group

          begin
              Chef::Mixin::Command.run_command(args)
          rescue Chef::Exceptions::Exec => e
              ::File.rename( @new_resource.path, "#{@new_resource.path}.failed" )
              raise e
          end
          FileUtils.touch createsPath
          new_resource.updated_by_last_action(true)
      else
          new_resource.updated_by_last_action(false)
      end
    end
  end
end


Chef::Platform.platforms[:default].merge! :s3_file => Chef::Provider::S3RemoteFile
Chef::Platform.platforms[:default].merge! :s3_artifact => Chef::Provider::S3Artifact

