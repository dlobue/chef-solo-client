
class Chef::Node
  def current_homedir
    etc.passwd[current_user].dir
  end
  def current_gid
    etc.passwd[current_user].gid
  end
  def current_group
    Etc.getgrgid(current_gid).name
  end
end

