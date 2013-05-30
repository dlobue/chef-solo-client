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

#Monkey patch the run_context class to use require instead of kernel.load
#require only loads a library once. calling it multiple times on the same file
#does nothing after the first time it is invoked.
#kernel.load however loads a library every time it is called, which breaks my
#monkey-patches. so it has to go.

class Chef
  class RunContext
    private

    def load_libraries
      foreach_cookbook_load_segment(:libraries) do |cookbook_name, filename|
        Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
        require filename
      end
    end
  end
end


