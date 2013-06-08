
service "procps" do
  action :nothing
  provider Chef::Provider::Service::Upstart
end

template "/etc/sysctl.d/60-chef-provided.conf" do
  not_if { node.sysctl.settings.to_hash.empty? }
  action :create
  source "extra_sysctl.conf.erb"
  mode 0644
  notifies :start, "service[procps]", :immediately
end

