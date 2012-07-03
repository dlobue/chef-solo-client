
include_recipe "misc::dotssh_dir"

cookbook_file "authorized_keys generator" do
    only_if { node.current_user == 'root' }
    source "generate_authorized_keys.py"
    path "/usr/local/bin/generate_authorized_keys.py"
    mode '0755'
    owner 'root'
    group 'root'
    notifies :run, "execute[generate authorized_keys]", :immediately
end

execute "generate authorized_keys" do
    only_if { node.current_user == 'root' }
    action :nothing
    command "/usr/local/bin/generate_authorized_keys.py -l #{node.env.s3_folder} #{node.env.s3_bucket} #{node.pubkey_folder} ubuntu"
    ignore_failure true
end

cron "generate authorized_keys" do
    only_if { node.current_user == 'root' }
    minute 0
    user "root"
    command "/usr/local/bin/generate_authorized_keys.py -l #{node.env.s3_folder} #{node.env.s3_bucket} #{node.pubkey_folder} ubuntu"
end

include_recipe "misc::dotssh_files"

