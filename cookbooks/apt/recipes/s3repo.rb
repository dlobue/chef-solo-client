# refactor to use 3rd party apt cookbook?
execute "apt-get update" do
  action :nothing
  retries 3
end

execute "add apt key" do
  only_if { node.apt.repo_key }
  command "apt-key adv --keyserver keyserver.ubuntu.com --recv #{node.apt.repo_key}"
  action :nothing
end

template (node.apt.sources_dir + "chef-given.list").to_s do
  owner "root"
  mode "0644"
  source "aptrepo.list.erb"
  notifies :run, resources(:execute => "add apt key"), :immediately
  notifies :run, resources(:execute => "apt-get update"), :immediately
end

