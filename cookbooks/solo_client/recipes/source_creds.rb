
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

