
require 'timeout'

DEFAULT_RUN_TIMEOUT = 60 * 60 * 12

#add a hook entry point that is executed before the chef run begins
#the primary use of this is to checkout the latest version of the cookbooks
#from git.
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
end



#monkey-patch the runner loop so that we can send it a SIGALRM and start the next loop early.
# this also is where the 'before_starting_run' hook is executed.
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
        Timeout::timeout(( Chef::Config[:run_timeout] or DEFAULT_RUN_TIMEOUT )) do
          # a chef run that takes more than 12 hours is inconceivable.
          # if a run takes longer, crash so that chef stands a chance of recovering on its own.
          # if more time is needed for whatever reason, the default run timeout can be overridden
          @chef_solo.run
        end
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


