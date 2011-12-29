
node.misc.users.each do |user|
    file File.expand_path("~#{user}/.ssh/authorized_keys") do
        owner user
        group user
        mode "0600"
    end
end

