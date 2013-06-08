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

