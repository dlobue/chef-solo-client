
template node.openssh.server_config.to_s do
  source 'sshd_config.erb'
  mode '0644'
  notifies :reload, "service[ssh]", :immediately
end

service "ssh" do
  provider Chef::Provider::Service::Upstart
  supports [:status, :restart, :reload]
  action :start
end

