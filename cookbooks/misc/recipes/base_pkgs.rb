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

node.lsb.codename
suite_pkg_names = {"precise" => { "ctags" => "exuberant-ctags" }}
pkg_names_override = suite_pkg_names[node.lsb.codename] || {}

%w{
  git-completion
  git-core
  rake
  apt-file
  gawk
  ctags
  cscope
  vim-doc
  vim-nox
  screen
}.each do |pkg|
  pkg_override = pkg_names_override[pkg]
  pkg = pkg_override unless pkg_override.nil?
  package pkg do
    action :upgrade
  end
end

