
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

