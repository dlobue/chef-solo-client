# I got tired of having to explicitly set the HOME env var when running a
# command as a different user than the one that chef is running as. This will
# automatically set it.
# It also ALWAYS sets output_on_failure to true unless it is already set. There
# is no reason why the default should be to be silent. It makes debugging
# rare/random problems impossible.

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

