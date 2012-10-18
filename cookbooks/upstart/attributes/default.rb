
require 'pathname'

default.upstart.system_conf_dir = Pathname.new '/etc/init'
default.upstart.user_conf_dir = Pathname.new(node.etc.passwd[node.current_user].dir) + '.init'
default.upstart.conf_dir = current_user == "root" ? upstart.system_conf_dir : upstart.user_conf_dir

