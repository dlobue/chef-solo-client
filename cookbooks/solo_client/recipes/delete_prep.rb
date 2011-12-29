
require 'json'

file 'delete_config' do
  only_if { node.not_dev }
  path node.delete_me_attribs
  content JSON.parse(File.read(Chef::Config[:json_attribs])).merge({"run_list"=>["recipe[solo_client::delete_me]"]}).to_json if node.not_dev
end

template "/etc/init/fates_deregister.conf" do
  only_if { node.not_dev }
  source "deregister.conf.erb"
  variables(
  )
end

