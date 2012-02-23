
class Chef::RunContext
  attr_accessor :subscription_queue
  alias _initialize initialize
  def initialize(node, cookbook_collection)
    @subscription_queue = Array.new
    _initialize(node, cookbook_collection)
  end
end

class Chef::Runner
  #def resolve_subscriptions
      #run_context.subscription_queue = Array.new if run_context.subscription_queue.nil?
      #loop do
        #break if run_context.subscription_queue.empty?

        #notification_spec = run_context.subscription_queue.pop()
        #run_context.resource_collection.find(notification_spec[:notifying_resource]).\
          #notifies(notification_spec[:action], notification_spec[:resource], notification_spec[:timing])
      #end
  #end

  alias _run_action run_action
  def run_action(resource, action)
    resource.resolve_notification_references
    _run_action(resource, action)
  end

  def converge
      run_context.subscription_queue = Array.new if run_context.subscription_queue.nil?
      run_context.subscription_queue.each do |notification_spec|
        run_context.resource_collection.find(notification_spec[:notifying_resource]).\
          notifies(notification_spec[:action], notification_spec[:resource], notification_spec[:timing])
      end

      # Execute each resource.
      run_context.resource_collection.execute_each_resource do |resource|
        # Resolve lazy/forward references in notifications
        resource.resolve_notification_references
        begin
          Chef::Log.debug("Processing #{resource} on #{run_context.node.name}")

          # Execute each of this resource's actions.
          Array(resource.action).each {|action| run_action(resource, action)}
        rescue => e
          Chef::Log.error("#{resource} (#{resource.source_line}) had an error:\n#{e}\n#{e.backtrace.join("\n")}")
          if resource.retries > 0
            resource.retries -= 1
            Chef::Log.info("Retrying execution of #{resource}, #{resource.retries} attempt(s) left")
            sleep resource.retry_delay
            retry
          end
          raise e unless resource.ignore_failure
        end
      end

      # Run all our :delayed actions
      delayed_actions.each do |notification|
        Chef::Log.info( "#{notification.notifying_resource} sending #{notification.action}"\
                        " action to #{notification.resource} (delayed)")
        # Struct of resource/action to call

        if not notification.resource.kind_of? Chef::Resource
          # Resolve all lazy/forward references in notifications
          # because sometimes, running a resource creates new notifications.
          # and sometimes, delayed resources do too.
          notification.notifying_resource.resolve_notification_references
        end

        run_action(notification.resource, notification.action)
      end

      true
  end
end

class Chef::Resource
  def subscribes(action, resources, timing=:delayed)
    run_context.subscription_queue = Array.new if run_context.subscription_queue.nil?
    resources = [resources].flatten
    resources.each do |resource|
      if resource.kind_of? Chef::Resource
        resource.notifies(action, self, timing)
      else
        run_context.subscription_queue << {:notifying_resource => resource, :action => action, :timing => timing, :resource => self}
      end
    end
    true
  end
end

