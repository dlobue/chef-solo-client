
package "openntpd" do
  action :upgrade
  notifies :stop, "service[openntpd]", :immediately
end

template node.openntpd.conf.to_s do
  owner "root"
  group "root"
  mode 0444
  notifies :stop, "service[openntpd]", :immediately
end

service "openntpd" do
  supports [:status, :restart]
  action [:enable, :start]
end

