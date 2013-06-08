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

solo_client_notify_hub "last_call" do
    action :nothing
end

solo_client_notify_hub "beginning" do
    action :notify
    notifies :notify, "solo_client_notify_hub[last_call]"
end

ruby_block "make_available" do
    action :nothing
    not_if { node.envswitch == "development" or not node.not_dev }
    block do
        node[:persist][:state] = "available" unless node[:persist][:state] == "available"
    end
    subscribes :create, "solo_client_notify_hub[last_call]"
end

