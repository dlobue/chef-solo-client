
action :notify do
    new_resource.updated_by_last_action(true)
end

