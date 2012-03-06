
cookbook_file "authorized_keys generator" do
  only_if { node.current_user == 'root' }
  source "delete_sdb_record.py"
  path "/usr/local/bin/delete_sdb_record.py"
  mode 0555
  owner 'root'
  group 'root'
end

template "/etc/init/chef_deregister.conf" do
  only_if { node.current_user == 'root' }
  source "deregister.conf.erb"
  mode 0644
  owner 'root'
  group 'root'
  variables(
  )
end

