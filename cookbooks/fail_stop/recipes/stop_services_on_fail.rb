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

Chef::Client.when_run_fails do |run_status|
  Chef::Log.error "run failed! stopping all known services"
  node = run_status.node
  next unless node.fail_stop.enabled #next ends the do block early

  run_status.
    run_context.
    resource_collection.
    all_resources.select { |resource|
      resource.resource_name == :service and not \
        [node.fail_stop.immune_services].flatten.include? resource.name
    }.each do |service|
      begin
      service.run_action :stop
      rescue Exception => e
        #TODO: stuff here
        Chef::Log.error e
      end
    end
end

