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

solo_client_untar_from_s3 "creds" do
    not_if { node.envswitch == "development" or node.continuous_deployment or not node.not_dev }
    user "root"
    container_path Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
    notifies :create, "ruby_block[apply_creds]", :immediately
end

ruby_block "apply_creds" do
    action :nothing
    block do
        Chef::Log.info("Need to restart chef run to get new creds in node. Raising sigalrm!.")
        raise SignalException, "SIGALRM"
    end
end

