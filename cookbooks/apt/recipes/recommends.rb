# by default ubuntu installs all recommended packages, despite the fact that
# they are merely recommended, not necessary for operation. Nice for a desktop,
# but not ideal for servers.

template "/etc/apt/apt.conf.d/10apt-recommends" do
  source "apt-recommends.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
  )
end

