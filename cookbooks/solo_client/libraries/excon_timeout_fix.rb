
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

