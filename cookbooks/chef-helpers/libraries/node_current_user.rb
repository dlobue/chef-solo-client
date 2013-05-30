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
#
# helpers to go along with node.current_user

class Chef::Node
  def current_homedir
    etc.passwd[current_user].dir
  end
  def current_gid
    etc.passwd[current_user].gid
  end
  def current_group
    Etc.getgrgid(current_gid).name
  end
end

