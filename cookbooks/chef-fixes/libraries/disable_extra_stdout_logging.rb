
# fix a change in chef that caused it to always log to STDOUT no matter what you want.

class Chef::Application::Solo

  def configure_logging
    Chef::Log.init(Chef::Config[:log_location])
    Chef::Log.level = Chef::Config[:log_level]
  end

end

