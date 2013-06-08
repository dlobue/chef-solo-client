
template node.misc.distutils_conf_file do
    action :create_if_missing
    source "distutils.cfg.erb"
    variables(
    )
end

