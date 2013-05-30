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

require 'timeout'
begin
    require 'fog'
    FOGFOUND = true unless defined? FOGFOUND
rescue LoadError => e
    Chef::Log.warn("Fog library not found. This is fine in development environments, but it is required in production.")
    FOGFOUND = false unless defined? FOGFOUND
end


module Excon
  class Connection
    private
    if FOGFOUND
      alias _socket socket
      def socket
        Timeout::timeout(@connection[:connect_timeout]) { _socket }
      end
    end
  end
end

