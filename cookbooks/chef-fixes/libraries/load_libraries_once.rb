
#Monkey patch the run_context class to use require instead of kernel.load
#require only loads a library once. calling it multiple times on the same file
#does nothing after the first time it is invoked.
#kernel.load however loads a library every time it is called, which breaks my
#monkey-patches. so it has to go.

class Chef
  class RunContext
    private

    def load_libraries
      foreach_cookbook_load_segment(:libraries) do |cookbook_name, filename|
        Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
        require filename
      end
    end
  end
end


