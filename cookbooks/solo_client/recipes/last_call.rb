
notify_hub "last_call" do
    action :nothing
end


notify_hub "delay_last_call" do
    action :notify
    notifies :notify, "notify_hub[last_call]"
end

