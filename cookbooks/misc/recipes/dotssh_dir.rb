
node.misc.users.each do |user|
    directory File.expand_path("~#{user}/.ssh") do
        owner user
        group user
        mode "0700"
    end
end

