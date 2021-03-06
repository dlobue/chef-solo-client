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
# chef makes dangerous assumptions that the state of a server will not change
# between the time that resources are converged, and the time that they are run.
# These assumptions usually cause chef to crash, or do other bad things. This
# forces chef to check service status before actually trying to make a change
# in service status.

class Chef::Provider::Service::Upstart
  UPSTART_STATE_FORMAT = /\w+ ((?:\(\w+\) )?(?:\w+\/)?)(\w+)/
    #no, that first capturing group is not necessary for the regex to work
    #but the code that uses that regex expects there to be 2 capturing groups
    #not that the data captured by the first capturing group is ever actually used
  alias _start_service start_service
  alias _stop_service stop_service
  alias _restart_service restart_service
  alias _reload_service reload_service

  def update_service_status
    # Get running/stopped state
    # We do not support searching for a service via ps when using upstart since status is a native
    # upstart function. We will however support status_command in case someone wants to do something special.
    if @new_resource.status_command
      Chef::Log.debug("#{@new_resource} you have specified a status command, running..")

      begin
        if run_command_with_systems_locale(:command => @new_resource.status_command) == 0
          @current_resource.running true
        end
      rescue Chef::Exceptions::Exec
        @current_resource.running false
        nil
      end
    else
      begin
        if upstart_state == "running"
          @current_resource.running true
        else
          @current_resource.running false
        end
      rescue Chef::Exceptions::Exec
        @current_resource.running false
        nil
      end
    end
  end

  def start_service
    update_service_status
    _start_service
  end

  def stop_service
    update_service_status
    _stop_service
  end

  def restart_service
    update_service_status
    _restart_service
  end

  def reload_service
    update_service_status
    _reload_service
  end
end

