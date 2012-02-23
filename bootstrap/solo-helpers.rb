cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
Ohai::Config[:plugin_path] << File.expand_path(File.join(cookbooks_path, '..', 'ohai_plugins'))

#add notifications that are run before the run begins
class Chef::Client
  def self.clear_notifications
    @pre_run_notifications = nil
    @run_start_notifications = nil
    @run_completed_successfully_notifications = nil
    @run_failed_notifications = nil
  end

  def self.pre_run_notifications
    @pre_run_notifications ||= []
  end

  def self.before_starting_run(&notification_block)
    pre_run_notifications << notification_block
  end

  def starts_next
    self.class.pre_run_notifications.each do |notification|
      notification.call(json_attribs)
    end
  end
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

class Chef::RunStatus
  attr_accessor :client
end

class Chef::RunList
  def insert(idx, run_list_item)
    run_list_item = run_list_item.kind_of?(RunListItem) ? run_list_item : parse_entry(run_list_item)
    @run_list_items.insert(idx, run_list_item) unless @run_list_items.include?(run_list_item)
    self
  end
end



Chef::Client.before_starting_run do |json_attribs|
    git_branch = Chef::Config[:git_branch]
    git_repo = Chef::Config[:git_repo]
    Chef::Log.info("Pulling down latest chef recipes in branch #{git_branch} from repo #{git_repo}.")
    cookbooks_path = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }
    repo_path = File.expand_path(File.join(cookbooks_path, '..'))
    if File.exists? cookbooks_path
        Chef::Log.debug("Looks like the repo already exists on disk. Checking to see if our branch is on the disk; if not perform a fetch.")
        #so i can follow the below command in the future:
        #get a list of all branches. if one of the branches in the list has
        #the same name as the repo we're supposed to be on, exit with non-zero
        #exit status to break the chain because we're done.
        #if the awk does not find the name of the branch we're supposed to be
        #on in the last, that means that the branch we're supposed to be on
        #isn't on disk, and a ``git pull`` won't suffice. so do a ``git fetch``
        #and then checkout the branch.
        cmd = "git branch -a | "
        cmd << "awk -F\"[ ]\" '"
        cmd <<       "$NF~/(^|\\/)#{git_branch.gsub('.','\.').gsub('/','\/')}$/{ exit 3 }' && "
        cmd << "( git fetch && git checkout #{git_branch} ) "
        Chef::Mixin::Command.run_command(:command => cmd,
                                         :returns => [0,3],
                                         :output_on_failure => true,
                                         :cwd => repo_path)

        Chef::Log.debug("Make sure we're on the right branch - if not check out branch #{git_branch}. Lastly perform a pull.")
        #so i can follow the below command in the future:
        #determine if the branch currently checked out is the branch we're supposed to be on.
        #if we are on the right branch, exit with non-zero to break the chain, because we
        #don't need to checkout the branch again.
        #otherwise, checkout the proper branch.
        #by now we should be on the right branch, so pull.
        cmd = "git branch | "
        cmd << "awk '/^\\*/{ if ($NF == \"#{git_branch.gsub('.','\.')}\" ) { exit 2 }}' && "
        cmd << "git checkout #{git_branch.gsub('.','\.')}; "
        cmd << "git pull && "
        cmd << "git submodule update --init --recursive"

        Chef::Mixin::Command.run_command(:command => cmd,
                                         :output_on_failure => true,
                                         :cwd => repo_path)

    else
        Chef::Log.debug("Appears the chef repo was never downloaded. Cloning the repo from #{git_repo} into #{repo_path}.")

        #Chef::Mixin::Command.run_command(:command => "git clone --recursive -b #{git_branch} #{git_repo} #{repo_path}")
        Chef::Mixin::Command.run_command(:command => "git clone #{git_repo} #{repo_path}",
                                         :output_on_failure => true)

        Chef::Log.debug("Make sure we're on the right branch - checking out branch #{git_branch}.")
        Chef::Mixin::Command.run_command(:command => "git checkout #{git_branch} && git submodule update --init --recursive",
                                         :output_on_failure => true,
                                         :cwd => repo_path)
    end
end

Chef::Client.when_run_starts do |run_status|
  use_lockr = Chef::Config[:use_lockr]
  if use_lockr
    run_status.node.run_list.insert(0, "recipe[solo_client::lockr_acquire]")
    run_status.node.run_list << "recipe[solo_client::lockr_release]"
    run_status.client._expand_runlist unless run_status.client.nil?
  end
end


#monkey-patch the runner loop so that we can send it a SIGALRM and start the next loop early.
class Chef::Application::Solo
  def run_application
    #TODO: add trap to catch SIGUSR1 and turn on debugging
    #TODO: do more cool stuff with signals and traps
    if Chef::Config[:daemonize]
      Chef::Daemon.daemonize("chef-client")
    end
    trap("ALRM") do
        raise SignalException, "SIGALRM"
    end
    e = nil

    loop do
      begin
        sleep Chef::Config[:interval] unless e.nil?

        @chef_solo = Chef::Client.new(@chef_solo_json)
        @chef_solo.starts_next
        @chef_solo.run
        @chef_solo = nil
        e = nil
        if Chef::Config[:interval]
          if Chef::Config[:splay]
            splay = rand Chef::Config[:splay]
            Chef::Log.debug("Splay sleep #{splay} seconds")
            sleep splay
          end

          Chef::Log.debug("Sleeping for #{Chef::Config[:interval]} seconds")
          sleep Chef::Config[:interval]
        else
          Chef::Application.exit! "Exiting", 0
        end
      rescue SystemExit => e
        raise
      rescue Exception => e
        if Chef::Config[:interval]
          if e.is_a? SignalException and e.message == "SIGALRM"
            Chef::Log.info("Caught SIGALRM - starting next run early.")
            e = nil
            retry
          end
          Chef::Log.error("#{e.class}")
          Chef::Log.fatal("#{e}\n#{e.backtrace.join("\n")}")
          Chef::Log.fatal("Sleeping for #{Chef::Config[:interval]} seconds before trying again")
          retry
        else
          raise
        end
      ensure
        GC.start
      end
    end
  end
end



#Monkey patch the run_context class to use require instead of kernel.load
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

