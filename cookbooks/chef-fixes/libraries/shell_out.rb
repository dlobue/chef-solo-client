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
# I got tired of having to explicitly set the HOME env var when running a
# command as a different user than the one that chef is running as. This will
# automatically set it.

require 'etc'

class Chef
    class ShellOut
        module Unix
            def set_environment
                _environment = environment
                if not uid.nil?
                    _environment['HOME'] = Etc.getpwuid(uid).dir unless _environment.has_key? 'HOME'
                end
                _environment.each do |env_var,value|
                    ENV[env_var] = value
                end
            end
        end
    end
end

