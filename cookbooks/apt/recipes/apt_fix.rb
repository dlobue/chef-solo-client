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
# this is a legacy recipe leftover from a broken AMI and not necessary for
# stuff to work, but since all it does is ensure the system is configured as it
# should be anyway, there's no harm

execute "apt-get update" do
    action :nothing
end

directory '/tmp' do
    owner 'root'
    group 'root'
    mode '1777'
    only_if { node.current_user == 'root' }
    notifies :run, resources(:execute => "apt-get update"), :immediately
end

