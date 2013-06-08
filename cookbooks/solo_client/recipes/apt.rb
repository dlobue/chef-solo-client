#
#   Copyright 2013 Geodelic
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

execute "apt-get update" do
  action :nothing
end

execute "add apt key" do
  command "apt-key adv --keyserver keyserver.ubuntu.com --recv #{node.apt.repo_key}"
  action :nothing
end

template "/etc/apt/sources.list.d/chef-given.list" do
  owner "root"
  mode "0644"
  source "aptrepo.list.erb"
  notifies :run, resources(:execute => "add apt key"), :immediately
  notifies :run, resources(:execute => "apt-get update"), :immediately
end

