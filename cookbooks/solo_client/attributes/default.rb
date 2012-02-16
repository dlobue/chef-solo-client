
#default.current_user = Etc.getpwuid(Process.uid).name if current_user.nil? #not 100% this will work, and the below method is good enough
default.current_user = "root" if current_user.nil?
default.fqdn = 'localhost'
default.deployment = 'development'
default.traits = []

default.delete_me_attribs = '/root/delete_me.rb'
default.pubkey_folder = 'public_keys'

default.ec2.region = ec2.placement_availability_zone[/^([a-zA-Z]*-[^-]+-[0-9]+)/,1] if attribute?("ec2")

override.command.ps = "ps aux" #lupyne and wand service checks fail because
                               #the default 'ps -ef' doens't have enough detail.

