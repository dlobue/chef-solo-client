
require 'fileutils'
require 'md5'

action :run do

    if new_resource.user.nil?
        user = node[:env][:user]
    else
        user = new_resource.user
    end


    Chef::Log.debug("untar_from_s3: artifact #{new_resource.artifact} to path #{new_resource.container_path}")
    Chef::Log.debug("untar_from_s3: user: #{user}")

    storage = Fog::Storage.new(get_creds().merge(:provider => 'AWS'))
    bucket = storage.directories.get(node.env.s3_bucket)

    artifacts = bucket.files.all(
        :prefix => [node.env.s3_folder, new_resource.artifact].join('/')
    ).to_a.select{ |k|
        not k.key.split('/')[-1].match(/.+-[^-]+\.t(ar\.)?(gz|bz2)/).nil?
    }

    raise "no artifacts found!" if artifacts.empty?

    artifact = artifacts[0]
    fileName = artifact.key.split('/')[-1]

    # First, see if there is a new archive to download.
    if node.chef_packages.chef.version.split('.')[1].to_i < 10
        cmd = "telegraph list_artifact #{node[:env][:s3_bucket]} #{node[:env][:s3_folder]} #{new_resource.artifact}"
        Chef::Log.debug("cmd: #{cmd}")
        output = `#{cmd}`
        if $?.to_i != 0
            raise "telegraph error:\n#{output}"
        end
        fileName = output.strip.split("\t")[0]
    else
        cmd = Chef::ShellOut.new("telegraph list_artifact #{node[:env][:s3_bucket]} #{node[:env][:s3_folder]} #{new_resource.artifact}")
        cmd.run_command
        cmd.error!
        fileName = cmd.stdout.strip.split("\t")[0]
    end


    archivePath = node[:env][:archive_dir] + fileName
    createsPath = new_resource.creates.start_with?('/') ? new_resource.creates : ::File.join(new_resource.container_path, new_resource.creates)

    #TODO: cleanup old and failed versions.
    #download block
    if ::File.exists?(archivePath)
        md5sum = MD5.hexdigest(::File.read(archivePath))
        raise "version on filesystem doesn't match the one on s3!" unless md5sum == artifact.etag
        #TODO: delete bad file
        #TODO: do something smarter that just raise
        Chef::Log.debug("latest version of artifact #{new_resource.artifact} already on disk. Skipping download and going straight to extraction.")
    else
        Chef::Log.info("downloading new archive to #{archivePath}")
        begin
            File.open(archivePath, 'w') {|local_file|
                local_file.write(artifact.body)} 
        rescue Chef::Exceptions::Exec => e
            ::File.delete( archivePath )
            raise e
        end
        FileUtils.touch archivePath
        FileUtils.chown(user, user, archivePath)
    end

    #TODO: check md5 of file we just downloaded to be sure it matches etag

    #extract block
    if not ::File.exists?(createsPath) or ::File.mtime(archivePath) > ::File.mtime(createsPath)
        #delete block
        if not new_resource.delete_dir_in_container.nil?
            Chef::Log.info("deleting dir_in_container: #{new_resource.container_path}/#{new_resource.delete_dir_in_container}")
            FileUtils.remove_dir( "#{new_resource.container_path}/#{new_resource.delete_dir_in_container}", true )
        end
        Chef::Log.info("untaring archive #{archivePath} to #{new_resource.container_path}")
        begin
            #TODO: support bzip2 compressed files
            Chef::Mixin::Command.run_command( :command => "tar -o -xzf #{archivePath} -C #{new_resource.container_path}", :user => user, :group => user)
        rescue Chef::Exceptions::Exec => e
            ::File.rename( archivePath, "#{archivePath}.failed" )
            raise e
        end
        FileUtils.touch createsPath
        new_resource.updated_by_last_action(true)
    end
end

