
template (node.sudoers.conf_dir + '00-preserve-ssh-agent').to_s do
  source "preserve-ssh-agent.erb"
  owner "root"
  group "root"
  mode 0440
end

