
directory "/var/log/upstart" do
  only_if { node.current_user == 'root' }
end

