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

require 'json'

file 'delete_config' do
  only_if { node.not_dev }
  path node.delete_me_attribs
  content JSON.parse(File.read(Chef::Config[:json_attribs])).merge({"run_list"=>["recipe[solo_client::delete_me]"]}).to_json if node.not_dev
end

template "/etc/init/fates_deregister.conf" do
  only_if { node.not_dev }
  source "deregister.conf.erb"
  variables(
  )
end

