
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

