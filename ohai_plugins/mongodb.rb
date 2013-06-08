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

require 'json'

provides "mongodb"

if File.exists?("/etc/mongodb.conf")
    port_lines = nil
    File.open("/etc/mongodb.conf") do |f|
        port_lines = f.grep(/^port/)
    end

    port_arg = nil
    if not port_lines.nil? and port_lines.length == 1
        port_arg = "--port " + port_lines[0].split('=')[-1].strip()
    end

    mongodb Mash.new JSON.parse(`mongo --quiet #{port_arg} --eval 'tojson(db.isMaster());' 2>/dev/null`)
end

