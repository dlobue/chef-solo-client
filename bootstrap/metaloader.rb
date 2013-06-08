#
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


require 'fileutils'
require 'pathname'

PRELOAD_COOKBOOKS = %W{chef-fixes}
COOKBOOK_CONTAINERS = [Chef::Config[:cookbook_path]].flatten.map { |d| Pathname.new d }

libdirs = PRELOAD_COOKBOOKS.map do |cbname|
  COOKBOOK_CONTAINERS.map { |cbroot|
    cbroot + cbname + 'libraries'
  }.select { |path|
    path.exist?
  }
end.flatten

def filter_libs(libdir)
  libdir = Pathname.new libdir unless libdir.kind_of? Pathname
  libdir.entries.map { |entry|
    libdir + entry
  }.select do |entry|
    entry.file? and entry.extname == '.rb'
  end
end

# load all the chef-fixes libraries
libdirs.map { |libdir| filter_libs libdir }.flatten.each do |lib|
  require lib.to_s
end

THIS_LIB = Pathname.new __FILE__
SKIP_LIBS = [THIS_LIB]
SKIP_LIBS.push THIS_LIB.realpath if THIS_LIB.symlink?

# load all the bootstrap helpers
filter_libs(File.dirname(__FILE__)).flatten.each do |lib|
  require lib.to_s unless SKIP_LIBS.include? lib
end

