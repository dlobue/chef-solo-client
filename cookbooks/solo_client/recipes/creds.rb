
cookbook_dir = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }

solo_client_untar_from_s3 "creds" do
    only_if { node.attribute?("get_creds") and node.get_creds }
    user "root"
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

