#
#   Copyright 2013 Geodelic
#   Copyright 2013 Dominic LoBue
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

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

