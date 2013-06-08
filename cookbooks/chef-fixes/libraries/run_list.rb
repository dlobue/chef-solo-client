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

class Chef::RunList
  def insert(idx, run_list_item)
    run_list_item = run_list_item.kind_of?(RunListItem) ? run_list_item : parse_entry(run_list_item)
    @run_list_items.insert(idx, run_list_item) unless @run_list_items.include?(run_list_item)
    self
  end
end

