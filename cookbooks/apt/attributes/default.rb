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

