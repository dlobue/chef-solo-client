#
#   Copyright 2013 Geodelic
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

#default.current_user = Etc.getpwuid(Process.uid).name if current_user.nil? #not 100% this will work, and the below method is good enough
default.current_user = "root" if current_user.nil?
default.fqdn = 'localhost'

default.delete_me_attribs = '/root/delete_me.rb'
default.pubkey_folder = 'public_keys'

default.ec2.region = ec2.placement_availability_zone[/^([a-zA-Z]*-[^-]+-[0-9]+)/,1] if attribute?("ec2")

override.command.ps = "ps aux" #lupyne and wand service checks fail because
                               #the default 'ps -ef' doens't have enough detail.

