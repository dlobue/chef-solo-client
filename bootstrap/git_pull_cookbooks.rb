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


cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
Ohai::Config[:plugin_path] << File.expand_path(File.join(cookbooks_path, '..', 'ohai_plugins'))



# pull down the latest cookbooks and recipes from git before every run.
# because of the placement of the 'before_starting_run' hook the git pull
# occurs before any of the recipes are loaded.
Chef::Client.before_starting_run do |json_attribs|
    git_branch = Chef::Config[:git_branch]
    git_repo = Chef::Config[:git_repo]
    Chef::Log.info("Pulling down latest chef recipes in branch #{git_branch} from repo #{git_repo}.")
    cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
    repo_path = File.expand_path(File.join(cookbooks_path, '..'))
    if File.exists? cookbooks_path
        Chef::Log.debug("Looks like the repo already exists on disk. Checking to see if our branch is on the disk; if not perform a fetch.")
        #so i can follow the below command in the future:
        #get a list of all branches. if one of the branches in the list has
        #the same name as the repo we're supposed to be on, exit with non-zero
        #exit status to break the chain because we're done.
        #if the awk does not find the name of the branch we're supposed to be
        #on in the last, that means that the branch we're supposed to be on
        #isn't on disk, and a ``git pull`` won't suffice. so do a ``git fetch``
        #and then checkout the branch.
        cmd = "git branch -a | "
        cmd << "awk -F\"[ ]\" '"
        cmd <<       "$NF~/(^|\\/)#{git_branch.gsub('.','\.').gsub('/','\/')}$/{ exit 3 }' && "
        cmd << "( git fetch && git checkout #{git_branch} ) "
        Chef::Mixin::Command.run_command(:command => cmd,
                                         :returns => [0,3],
                                         :output_on_failure => true,
                                         :cwd => repo_path)

        Chef::Log.debug("Make sure we're on the right branch - if not check out branch #{git_branch}. Lastly perform a pull.")
        #so i can follow the below command in the future:
        #determine if the branch currently checked out is the branch we're supposed to be on.
        #if we are on the right branch, exit with non-zero to break the chain, because we
        #don't need to checkout the branch again.
        #otherwise, checkout the proper branch.
        #by now we should be on the right branch, so pull.
        cmd = "git branch | "
        cmd << "awk '/^\\*/{ if ($NF == \"#{git_branch.gsub('.','\.')}\" ) { exit 2 }}' && "
        cmd << "git checkout #{git_branch.gsub('.','\.')}; "
        cmd << "git pull && "
        cmd << "git submodule update --init --recursive"

        Chef::Mixin::Command.run_command(:command => cmd,
                                         :output_on_failure => true,
                                         :cwd => repo_path)

    else
        Chef::Log.debug("Appears the chef repo was never downloaded. Cloning the repo from #{git_repo} into #{repo_path}.")

        #Chef::Mixin::Command.run_command(:command => "git clone --recursive -b #{git_branch} #{git_repo} #{repo_path}")
        Chef::Mixin::Command.run_command(:command => "git clone #{git_repo} #{repo_path}",
                                         :output_on_failure => true)

        Chef::Log.debug("Make sure we're on the right branch - checking out branch #{git_branch}.")
        Chef::Mixin::Command.run_command(:command => "git checkout #{git_branch} && git submodule update --init --recursive",
                                         :output_on_failure => true,
                                         :cwd => repo_path)
    end
end


