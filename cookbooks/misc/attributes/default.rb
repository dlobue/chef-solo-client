
default.misc.egg_script_dir = '/usr/bin'
default.misc.distutils_conf_file = '/root/.pydistutils.cfg'

default.deployment_color = 'none'
default.mounts = {}

default.misc.extrausers = []
default.misc.users = Promise.new do (['root'] + [misc.extrausers].flatten + [
        'ubuntu',
    ]).uniq.select do |user|
        etc.passwd.has_key?(user) and not ['nologin', 'false'].include?(
            etc.passwd[user.to_sym].shell.split('/')[-1]
        )
    end
end

