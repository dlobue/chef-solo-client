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
# this recipe puts the chef-repo_git-hook_post-merge file into this repo's
# git hooks folder. The idea is to restart chef-solo when a library file is updated.
# this is necessary when chef is running as a daemon in production to get
# around the fact that chef does not reload library files.

cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
git_hooks_path = File.expand_path(File.join(cookbooks_path, '..', '.git', 'hooks'))

cookbook_file "#{git_hooks_path}/post-merge" do
    not_if { node.envswitch == "development" or node.continuous_deployment or not node.not_dev }
    only_if { File.exists?(git_hooks_path) }
    source "chef-repo_git-hook_post-merge"
    owner "root"
    group "root"
    mode 0755
end

