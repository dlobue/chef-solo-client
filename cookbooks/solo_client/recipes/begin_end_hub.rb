
solo_client_notify_hub "last_call" do
    action :nothing
end

solo_client_notify_hub "beginning" do
    action :notify
    notifies :notify, "solo_client_notify_hub[last_call]"
end

ruby_block "make_available" do
    action :nothing
    not_if { node.envswitch == "development" or not node.not_dev }
    block do
        node[:persist][:state] = "available" unless node[:persist][:state] == "available"
    end
    subscribes :create, "solo_client_notify_hub[last_call]"
end

