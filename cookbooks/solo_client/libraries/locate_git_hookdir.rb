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

require 'set'
require 'pathname'


PATH_PREFIX = /^[\t ]+path = /
REDIRECT_PREFIX = 'gitdir: '

def resolve_git_dir(gitpath)
  gitpath = Pathname.new gitpath unless gitpath.kind_of? Pathname
  return gitpath if gitpath.directory?

  raise "unable to read .git file" unless gitpath.readable?
  contents = gitpath.read
  raise "unrecognized format!: >#{contents}<" unless contents.start_with? REDIRECT_PREFIX
  gitpath.dirname + contents[REDIRECT_PREFIX.length..-1].strip
end

def locate_git_dir(dir)
  dir = Pathname.new dir unless dir.kind_of? Pathname
  until (dir + '.git').exist?
    dir = dir + '..'
  end
  dir
end

def recursive_locate_git_dirs(dir, results=nil)
  results = [] if results.nil?
  dir = Pathname.new dir unless dir.kind_of? Pathname
  dir = locate_git_dir(dir)

  gitpath = dir + '.git'
  results << resolve_git_dir( gitpath )

  gitmodules = dir + '.gitmodules'
  if gitmodules.exist? and gitmodules.readable?
    gitmodules.open do |f|
      f.grep(PATH_PREFIX).each do |l|
        recursive_locate_git_dirs(dir + l[l.index('=')+1..-1].strip, results)
      end
    end
  end
  results
end

def find_cookbook_hookdirs
  [Chef::Config[:cookbook_path]].flatten.map { |cookbook|
    recursive_locate_git_dirs cookbook
  }.flatten.uniq.map do |gitdir|
    gitdir + 'hooks'
  end
end

