#
#   Copyright 2013 Geodelic
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
# this recipe puts the chef-repo_git-hook_post-merge file into this repo's
# git hooks folder. The idea is to restart chef-solo when a library file is updated.
# this is necessary when chef is running as a daemon in production to get
# around the fact that chef does not reload library files.

find_cookbook_hookdirs.each do |hookdir|
    template (hookdir + "post-merge").to_s do
        only_if { hookdir.directory? }
        source "chef-repo_git-hook_post-merge"
        mode 0755
    end
end

