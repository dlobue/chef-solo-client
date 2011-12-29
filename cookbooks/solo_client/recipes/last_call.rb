
solo_client_notify_hub "last_call" do
    action :nothing
end


solo_client_notify_hub "delay_last_call" do
    action :notify
    notifies :notify, "solo_client_notify_hub[last_call]"
end

