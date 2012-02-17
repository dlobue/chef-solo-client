
class Chef::Provider::Git

  def checkout
    sha_ref = target_revision
    # checkout into a local branch rather than a detached HEAD
    shell_out!("git checkout -b deploy", run_options(:cwd => @new_resource.destination))
    Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision} reference: #{sha_ref}"
  end

  def enable_submodules
    if @new_resource.enable_submodules
      Chef::Log.info "#{@new_resource} enabling git submodules"
      command = "git submodule update --init --recursive"
      shell_out!(command, run_options(:cwd => @new_resource.destination, :command_log_level => :info))
    end
  end
end

