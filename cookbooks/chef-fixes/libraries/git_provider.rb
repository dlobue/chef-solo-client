
class Chef::Provider::Git
  def dereferenced_target_revision
    targetrev = target_revision
    # a 128 means not found
    result = shell_out!("git rev-parse #{targetrev}^{commit}", :cwd => cwd, :returns => [0,128]).stdout.strip
    sha_hash?(result) ? result : targetrev
  end

  def current_revision_matches_target_revision?
    revmatch = ((!@current_resource.revision.nil?) &&
                (dereferenced_target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
               )
    return revmatch unless revmatch
    command = "git diff --no-ext-diff --quiet --exit-code HEAD"
    shell_out!(command, :cwd => @new_resource.destination, :returns => [0,1]).exitstatus == 0
  end

  def checkout
    sha_ref = target_revision
    # checkout into a local branch rather than a detached HEAD
    shell_out!("git checkout -b deploy", run_options(:cwd => @new_resource.destination))
    Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision} reference: #{sha_ref}"
  end

  def enable_submodules
    if @new_resource.enable_submodules
      Chef::Log.info "#{@new_resource} enabling git submodules"
      command = 'git submodule foreach --recursive "git reset --hard; git fetch; git fetch --tags"'
      command << " && git submodule update --init --recursive"
      shell_out!(command, run_options(:cwd => @new_resource.destination, :command_log_level => :info))
    end
  end
end

