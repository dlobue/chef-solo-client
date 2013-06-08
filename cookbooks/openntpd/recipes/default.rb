#
#   Copyright 2013 Dominic LoBue
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

