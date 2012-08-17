
require 'pathname'

default.openssh.conf_dir = Pathname.new '/etc/ssh'
default.openssh.server_config = Promise.new { openssh.conf_dir + 'sshd_config' }

default.openssh.max_startups = 100

