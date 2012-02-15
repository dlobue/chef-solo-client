
execute "apt-get update" do
    action :nothing
end

directory '/tmp' do
    owner 'root'
    group 'root'
    mode '1777'
    only_if { node.current_user == 'root' }
    notifies :run, resources(:execute => "apt-get update"), :immediately
end

