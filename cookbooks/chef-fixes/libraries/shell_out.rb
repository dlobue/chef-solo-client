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

