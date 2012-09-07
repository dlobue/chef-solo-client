

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
  libdir = Pathname.new unless libdir.kind_of? Pathname
  libdir.entries.select { |entry|
    entry.file? and entry.extname == '.rb'
  }.map do |entry|
    libdir + entry
  end
end

# load all the chef-fixes libraries
libdirs.map { |libdir| filter_libs libdir }.each do |lib|
  require lib.to_s
end

# load all the bootstrap helpers
filter_libs(File.dirname(__FILE__)).each do |lib|
  lib = lib.to_s
  require lib unless lib == __FILE__
end

