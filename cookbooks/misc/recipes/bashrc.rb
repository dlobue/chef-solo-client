
node.misc.users.each do |user|
    template File.expand_path("~#{user}/.bashrc") do
        source "bashrc.erb"
        owner user
        group user
        variables(
        )
    end

    template File.expand_path("~#{user}/.inputrc") do
        source "inputrc.erb"
        owner user
        group user
        variables(
        )
    end

    template File.expand_path("~#{user}/.bash_logout") do
        source "bash_logout.erb"
        owner user
        group user
        variables(
        )
    end
end

