
provides 'current_user'

require 'etc'

current_user Etc.getpwuid.name

