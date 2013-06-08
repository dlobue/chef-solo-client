
Chef::Client.when_run_fails do |run_status|
  Chef::Log.error "run failed! stopping all known services"
  node = run_status.node
  next unless node.fail_stop.enabled #next ends the do block early

  run_status.
    run_context.
    resource_collection.
    all_resources.select { |resource|
      resource.resource_name == :service and not \
        [node.fail_stop.immune_services].flatten.include? resource.name
    }.each do |service|
      begin
      service.run_action :stop
      rescue Exception => e
        #TODO: stuff here
        Chef::Log.error e
      end
    end
end

