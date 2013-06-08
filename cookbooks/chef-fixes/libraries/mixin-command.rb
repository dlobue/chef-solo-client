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

require 'etc'

class Chef
  module Mixin
    module Command
      alias _run_command run_command
      def run_command(args={})
        args[:output_on_failure] ||= true

        if args[:user] and not (args[:environment] and (args[:environment]["HOME"] or args[:environment][:HOME]))
          args[:environment] ||= {}
          if args[:user].kind_of? Integer
            args[:environment]["HOME"] ||= Etc.getpwuid(args[:user]).dir
          else
            args[:environment]["HOME"] ||= Etc.getpwnam(args[:user]).dir
          end
        end

        Chef::Log.debug("In chef-fixes mixin command. args is: #{args.inspect}")
        _run_command(args)
      end
    end
  end
end

