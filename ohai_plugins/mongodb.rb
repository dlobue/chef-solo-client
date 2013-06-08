
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

