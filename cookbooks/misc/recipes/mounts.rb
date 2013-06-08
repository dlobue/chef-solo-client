

if node.attribute?("mounts") and not node.mounts.empty?
    package "disktype"
    node.mounts.each do |dev,mountpoint|
        script "filesystem #{dev}" do
            interpreter "bash"
            code <<-EOH
            test -b #{dev} || exit 1

            disktype #{dev} | awk 'BEGIN{ blank=0 }; /^--- /{getline; getline; if (/^Blank /) { blank=1 }}; END{ if (blank) { exit 2 }}'
            ret=$?
            if [ $ret -eq 2 ]; then
                echo y | mkfs -t ext3 -j #{dev}
            fi
            EOH
        end

        directory mountpoint

        mount mountpoint do
            device dev
            fstype "ext3"
        end
    end
end

