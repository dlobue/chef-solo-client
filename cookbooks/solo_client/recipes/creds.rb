#
#   Copyright 2013 Dominic LoBue
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

include_recipe "solo_client::default"

cookbook_dir = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }

s3_file "creds" do
  only_if { node.attribute?("get_creds") and node.get_creds }
  action :create_artifact
  bucket node.env.s3_bucket
  folder node.env.s3_folder
  path (node.env.archive_dir + "#{name}.tgz").to_s
end

untar_archive "creds" do
  only_if { node.attribute?("get_creds") and node.get_creds }
  path (node.env.archive_dir + "#{name}.tgz").to_s
  container_path cookbook_dir
  creates File.join(cookbook_dir, 'cred_cookbook')
  notifies :create, "ruby_block[apply_creds]", :immediately
end

ruby_block "apply_creds" do
    action :nothing
    block do
        Chef::Log.info("Need to restart chef run to get new creds in node. Raising sigalrm!.")
        raise SignalException, "SIGALRM"
    end
end

