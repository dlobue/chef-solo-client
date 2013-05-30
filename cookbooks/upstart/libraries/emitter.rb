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

class Chef::Resource
  class UpstartEvent < Chef::Resource::Execute
    def initialize(name, run_context=nil)
      super
      @resource_name = :upstart_event
      @provider = Chef::Provider::Execute
      #@provider = Chef::Provider::UpstartEmit
      @command = "/sbin/initctl emit"
      @event = name
      @wait = true
      @variables = Hash.new
    end

    def command(arg=nil)
      if not arg.nil?
        super
        #@command = arg
      else
        [
          @command,
          event,
          ('--no-wait' unless wait),
          (variables.map { |i| i.join('=') } unless variables.nil? or variables.empty?)
        ].select { |x| not x.nil? }.join(' ')
      end
    end

    def event(arg=nil)
      set_or_return(
        :event,
        arg,
        :kind_of => String
      )
    end

    def wait(arg=nil)
      set_or_return(
        :wait,
        arg,
        :kind_of => [ TrueClass, FalseClass ]
      )
    end

    def variables(arg=nil)
      set_or_return(
        :variables,
        arg,
        :kind_of => Hash
      )
    end
  end
end

