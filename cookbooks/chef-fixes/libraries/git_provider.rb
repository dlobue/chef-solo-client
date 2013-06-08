#
#   Copyright 2013 Dominic LoBue
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
# Add support for corner cases never envisioned by the original authors of the resource. it also adds support for enforcing a git repository to match the specified revision (manually edited files are reset)

class Chef::Provider::Git

  def dereferenced_target_revision
    targetrev = target_revision
    # a 128 means not found, which is fine and expected.
    result = shell_out!("git rev-parse #{targetrev}^{commit}", :cwd => cwd, :returns => [0,128]).stdout.strip
    # if our attempts to dereference the target revision fail, just send back the target revision.
    sha_hash?(result) ? result : targetrev
  end

  def current_revision_matches_target_revision?
    # dereference the target revision sha so annotated tags don't throw us for a loop.
    revmatch = ((!@current_resource.revision.nil?) &&
                (dereferenced_target_revision.strip.to_i(16) == @current_resource.revision.strip.to_i(16))
               )
    return revmatch unless revmatch
    # check that the revision matches the checked out HEAD. guards against
    # manually edited files and ensures submodules are on the correct revision.
    # the --ignore-submodules=untracked option makes git diff ignore untracked
    # files in submodule, so they won't cause chef to freak out if a random log
    # file sits around.
    command = "git diff --no-ext-diff --quiet --exit-code --ignore-submodules=untracked HEAD"
    shell_out!(command, :cwd => @new_resource.destination, :returns => [0,1]).exitstatus == 0
  end

  def checkout
    sha_ref = target_revision
    # checkout into a local branch rather than a detached HEAD
    shell_out!("git checkout -b deploy", run_options(:cwd => @new_resource.destination))
    Chef::Log.info "#{@new_resource} checked out branch: #{@new_resource.revision} reference: #{sha_ref}"
  end

  def enable_submodules
    # Adds support for recursive submodules, and for submodules that specify
    # commits that are only referenced by tags
    if @new_resource.enable_submodules
      Chef::Log.info "#{@new_resource} enabling git submodules"
      command = 'git submodule foreach --recursive "git reset --hard; git fetch; git fetch --tags"'
      command << " && git submodule update --init --recursive"
      shell_out!(command, run_options(:cwd => @new_resource.destination, :command_log_level => :info))
    end
  end
end

