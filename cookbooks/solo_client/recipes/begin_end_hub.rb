
notify_hub "last_call" do
    action :nothing
end

notify_hub "beginning" do
    action :notify
    notifies :notify, "notify_hub[last_call]"
end

ruby_block "make_available" do
    action :nothing
    block do
        node[:persist][:state] = "available" unless node[:persist][:state] == "available"
    end
    subscribes :create, "notify_hub[last_call]"
end

