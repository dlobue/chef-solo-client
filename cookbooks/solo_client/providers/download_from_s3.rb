
require 'fileutils'
require 'md5'
require 'fog'

action :run do

    if new_resource.user.nil?
        user = node[:env][:geo_user]
    else
        user = new_resource.user
    end


    Chef::Log.debug("download_from_s3: artifact #{new_resource.artifact}")
    Chef::Log.debug("download_from_s3: user: #{user}")


    #TODO: refactor into library so untar_from_s3 and download_from_s3 can reuse code
    storage = Fog::Storage.new(get_creds().merge(:provider => 'AWS'))
    bucket = storage.directories.get(node.env.s3_bucket)

    # First, see if there is a new archive to download.
    artifacts = bucket.files.all(
        :prefix => [node.env.s3_folder, new_resource.artifact].join('/')
    ).to_a.select{ |k|
        not k.key.split('/')[-1].match(/.+-[^-]+\.t(ar\.)?(gz|bz2)/).nil?
    }

    raise "no artifacts found!" if artifacts.empty?

    artifact = artifacts[0]
    fileName = artifact.key.split('/')[-1]

    archivePath = node[:env][:archive_dir] + fileName

    #TODO: cleanup old and failed versions.
    #download block
    if ::File.exists?(archivePath)
        md5sum = MD5.hexdigest(::File.read(archivePath))
        raise "version on filesystem doesn't match the one on s3!" unless md5sum == artifact.etag
        #TODO: delete bad file
        #TODO: do something smarter that just raise
        Chef::Log.debug("latest version of artifact #{new_resource.artifact} already on disk.")
        new_resource.updated_by_last_action(false)
    else
        Chef::Log.info("downloading new artifact to #{archivePath}")
        begin
            ::File.open(archivePath, 'w') {|local_file|
                local_file.write(artifact.body)}
        rescue Chef::Exceptions::Exec => e
            ::File.delete( archivePath )
            raise e
        end
        FileUtils.touch archivePath
        FileUtils.chown(user, user, archivePath)
        new_resource.updated_by_last_action(true)
    end

    #TODO: check md5 of file we just downloaded to be sure it matches etag
end

