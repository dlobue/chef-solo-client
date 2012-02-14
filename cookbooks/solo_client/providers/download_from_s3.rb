
action :run do

    if new_resource.user.nil?
        user = node[:env][:geo_user]
    else
        user = new_resource.user
    end


    Chef::Log.debug("download_from_s3: artifact #{new_resource.artifact}")
    Chef::Log.debug("download_from_s3: user: #{user}")

    # First, see if there is a new archive to download.
    cmd = "telegraph list_artifact #{node[:env][:s3_bucket]} #{node[:env][:s3_folder]} #{new_resource.artifact}"
    Chef::Log.debug("cmd: #{cmd}")
    output = `#{cmd}`
    if $?.to_i != 0
        raise "telegraph error:\n#{output}"
    end
    fileName = output.strip.split("\t")[0]

    if node[:persist]["artifact_#{new_resource.artifact}".to_sym] == fileName
        Chef::Log.debug("Artifact #{new_resource.artifact} already in place.")
        new_resource.updated_by_last_action(false)
    else

        archivePath = node[:env][:archive_dir_Pathname] + fileName
        if ::File.exists?(archivePath)
            Chef::Log.debug("latest version of artifact #{new_resource.artifact} already on disk. Skipping download and going straight to extraction.")
        else
            if node[:persist]["artifact_#{new_resource.artifact}".to_sym]
                Chef::Log.info("getting rid of old version of artifact: rm -rf #{node[:env][:archive_dir_Pathname] + node[:persist]["artifact_#{new_resource.artifact}".to_sym]}")
                Chef::Mixin::Command.run_command(
                    :command => "rm -rf #{node[:env][:archive_dir_Pathname] + node[:persist]["artifact_#{new_resource.artifact}".to_sym]}" # scary
                )
            end
            Chef::Log.info("downloading new artifact to #{archivePath}")
            Chef::Mixin::Command.run_command(
                :command => "telegraph download_file #{node[:env][:s3_bucket]} #{node[:env][:s3_folder]}/#{fileName} #{archivePath}",
                :user => user,
                :group => user,
                :environment => {"HOME"=> ::File.expand_path("~#{user}")}
            )
        end
        node[:persist]["artifact_#{new_resource.artifact}".to_sym] = fileName
        new_resource.updated_by_last_action(true)
    end
end

