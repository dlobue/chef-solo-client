# this recipe puts the chef-repo_git-hook_post-merge file into this repo's
# git hooks folder. The idea is to restart chef-solo when a library file is updated.
# this is necessary when chef is running as a daemon in production to get
# around the fact that chef does not reload library files.

cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
git_hooks_path = File.expand_path(File.join(cookbooks_path, '..', '.git', 'hooks'))

cookbook_file "#{git_hooks_path}/post-merge" do
    only_if { File.exists?(git_hooks_path) }
    source "chef-repo_git-hook_post-merge"
    owner "root"
    group "root"
    mode 0755
end

