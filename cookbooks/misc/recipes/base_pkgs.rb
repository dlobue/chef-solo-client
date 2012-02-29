
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
  package pkg do
    action :upgrade
  end
end

