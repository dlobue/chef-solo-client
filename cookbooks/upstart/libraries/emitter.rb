
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
          '--no-wait' unless wait,
          variables.map { |i| i.join('=') } unless variables.nil? or variables.empty?
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

