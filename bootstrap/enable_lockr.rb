

# to rule out the possibility of human error (forgetting to add a the
# lockr_acquire recipe to the runlist, or adding it in the wrong place), use a
# hook to insert the lockr_acquire recipe in the run_list so we can be sure
# that we'll never have downtime before chef was updating code.
Chef::Client.when_run_starts do |run_status|
  if Chef::Config[:use_lockr]
    run_status.node.run_list.insert(0, "recipe[solo_client::lockr_acquire]")
    run_status.client._expand_runlist unless run_status.client.nil?
  end
end

Chef::Client.when_run_completes_successfully do |run_status|
  release_lockr(run_status.node) if Chef::Config[:use_lockr]
end



