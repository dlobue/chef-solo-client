
ruby_block "make_available" do
    action :nothing
    block do
        node[:persist][:state] = "available" unless node[:persist][:state] == "available"
    end
    subscribe :notify, "notify_hub[last_call]"
end

