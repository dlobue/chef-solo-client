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

#sometime between chef 0.9.18 and 0.10.4 chef was refactored in a way
#that broke the hook I used to ensure that the global lock was
#always grabbed before any recipes were executed. this is to add the hook
#back in.

class Chef::Client
  if public_method_defined? :setup_run_context
    alias _build_node build_node
    def build_node
      _build_node
      @run_status.client = self
      @node
    end
    def _expand_runlist
      @run_list_expansion = @node.expand!('disk')
    end
  end
end

#another part of my fix for the chef refactoring that broke my lockr insertion
#point
class Chef::RunStatus
  attr_accessor :client
end

