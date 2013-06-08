
ruby_block "release lockr" do
    action :nothing
    not_if { node[:persist][:state] == 'pending' }
    block do
        release_lockr(node)
    end
end

ruby_block "final resource" do
    action :create
    block do
    end
    notifies :create, "ruby_block[release lockr]"
end

