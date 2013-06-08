#
#   Copyright 2013 Geodelic
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

action :run do

    if new_resource.user.nil?
        user = node[:env][:geo_user]
    else
        user = new_resource.user
    end


    Chef::Log.debug("untar_from_s3: artifact #{new_resource.artifact} to path #{new_resource.container_path}")
    Chef::Log.debug("untar_from_s3: user: #{user}")

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
            Chef::Log.info("downloading new archive to #{archivePath}")
            Chef::Mixin::Command.run_command(
                :command => "telegraph download_file #{node[:env][:s3_bucket]} #{node[:env][:s3_folder]}/#{fileName} #{archivePath}"
            )
            Chef::Mixin::Command.run_command(
                :command => "chown #{user}:#{user} #{archivePath}"
            )
        end
        if not new_resource.delete_dir_in_container.nil?
            Chef::Log.info("deleting dir_in_container: rm -rf #{new_resource.container_path}/#{new_resource.delete_dir_in_container}")
            Chef::Mixin::Command.run_command(
                :command => "rm -rf #{new_resource.container_path}/#{new_resource.delete_dir_in_container}" # scary
            )
        end
        Chef::Log.info("untaring archive #{archivePath} to #{new_resource.container_path}")
        begin
            Chef::Mixin::Command.run_command(
                :command => "tar -o -xzf #{archivePath} -C #{new_resource.container_path}",
                :user => user,
                :group => user
            )
        rescue Chef::Exceptions::Exec => e
            Chef::Mixin::Command.run_command(
                :command => "mv #{archivePath} #{archivePath}.failed"
            )
            raise ArtifactExtractionError, "untarring #{archivePath} failed for some reason."
        end
        node[:persist]["artifact_#{new_resource.artifact}".to_sym] = fileName
        new_resource.updated_by_last_action(true)
    end
end

