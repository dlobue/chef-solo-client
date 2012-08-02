# This recipe is to create the /var/log/upstart directory, which for some
# reason doesn't exist in ubuntu AMIs, and upstart won't create it on its own.
# As a result without this directory logs for jobs with 'console log' won't be
# created.

directory "/var/log/upstart" do
  only_if { node.current_user == 'root' }
end

