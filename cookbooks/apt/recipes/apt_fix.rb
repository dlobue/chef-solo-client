# this is a legacy recipe leftover from a broken AMI and not necessary for
# stuff to work, but since all it does is ensure the system is configured as it
# should be anyway, there's no harm

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

