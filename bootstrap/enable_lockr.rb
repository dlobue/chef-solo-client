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


# to rule out the possibility of human error (forgetting to add a the
# lockr_acquire recipe to the runlist, or adding it in the wrong place), use a
# hook to insert the lockr_acquire recipe in the run_list so we can be sure
# that we'll never have downtime before chef was updating code.
Chef::Client.when_run_starts do |run_status|
  if Chef::Config[:use_lockr]
    run_status.node.run_list.insert(0, "recipe[solo_client::lockr_acquire]")
    run_status.client._expand_runlist unless run_status.client.nil?
  end
end

Chef::Client.when_run_completes_successfully do |run_status|
  release_lockr(run_status.node) if Chef::Config[:use_lockr]
end



