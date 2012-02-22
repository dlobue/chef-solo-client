
default.apt.repo_key = nil
default.apt.bucket = nil
default.apt.distro = os == "darwin" ? "darwin" : lsb.codename
default.apt.components = %w{main}

default.apt.aws_access_key_id = nil
default.apt.aws_secret_access_key = nil

default.apt.install_recommends = false
default.apt.install_suggests = false

