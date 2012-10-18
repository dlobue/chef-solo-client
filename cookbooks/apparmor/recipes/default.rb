
service "apparmor" do
  action :nothing
  supports [ :restart, :reload, :status ]
end

