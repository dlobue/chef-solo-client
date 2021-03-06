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
# This recipe is to create the /var/log/upstart directory, which for some
# reason doesn't exist in ubuntu AMIs, and upstart won't create it on its own.
# As a result without this directory logs for jobs with 'console log' won't be
# created.

directory "/var/log/upstart" do
  only_if { node.current_user == 'root' }
end

