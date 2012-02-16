
template "/etc/apt/apt.conf.d/10apt-recommends" do
  source "apt-recommends.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
  )
end

