
#sometime between chef 0.9.18 and 0.10.4 chef was refactored in a way
#that broke the hook I used to ensure that the global lock was
#always grabbed before any recipes were executed. this is to add the hook
#back in.

class Chef::Client
  if public_method_defined? :setup_run_context
    alias _build_node build_node
    def build_node
      _build_node
      @run_status.client = self
      @node
    end
    def _expand_runlist
      @run_list_expansion = @node.expand!('disk')
    end
  end
end

#another part of my fix for the chef refactoring that broke my lockr insertion
#point
class Chef::RunStatus
  attr_accessor :client
end

