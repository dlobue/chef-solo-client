
include_attribute "solo_client::default"

default.apt.repo_key = nil
default.apt.bucket = nil
default.apt.distro = os == "darwin" ? "darwin" : lsb.codename
default.apt.components = %w{main}
default.apt.arches = %w{all amd64}
default.apt.config_dir = Pathname.new "/etc/apt"
default.apt.sources_dir = Promise.new { apt.config_dir + 'sources.list.d' }

default.apt.s3_endpoint = case ( attribute?("ec2") ? ec2.region : nil )
                          when "us-east-1",nil
                            "s3.amazonaws.com"
                          else
                            "s3-#{ec2.region}.amazonaws.com"
                          end

default.apt.aws_access_key_id = nil
default.apt.aws_secret_access_key = nil

default.apt.install_recommends = false
default.apt.install_suggests = false

