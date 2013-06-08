#
#   Copyright 2013 Geodelic
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

ruby_block "load aws creds" do
    not_if { node.envswitch == 'development' }
    only_if { ENV['AWS_SOMETHING'].nil? }
    block do
        f = File.open('/root/.aws_creds')
        f.each do |line|
            line = line.slice(7, line.length) if line.slice(0,7) == 'export '
            line = line.gsub(/['"]/, "").split('=').map {|x| x.strip }
            if line.length != 2
                next
            end
            ENV[line[0]] = line[1]
        end
        f.close
    end
end

