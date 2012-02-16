
default.apt.repo_key = nil
default.apt.bucket = nil
default.apt.distro = os == "darwin" ? "darwin" : lsb.codename
default.apt.components = %w{main}

default.apt.install_recommends = false
default.apt.install_suggests = false

