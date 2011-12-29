
execute "apt-get update" do
  action :nothing
end

execute "add apt key" do
  command "apt-key adv --keyserver keyserver.ubuntu.com --recv #{node.repo_key}"
  action :nothing
end

template "/etc/apt/sources.list.d/chef-given.list" do
  owner "root"
  mode "0644"
  source "aptrepo.list.erb"
  notifies :run, resources(:execute => "add geodelic apt key"), :immediately
  notifies :run, resources(:execute => "apt-get update"), :immediately
end

