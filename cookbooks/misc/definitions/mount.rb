
define :format_and_mount, :dev, :mountpoint do
    package "disktype"

    script "filesystem #{params[:dev]}" do
        interpreter "bash"
        code <<-EOH
        test -b #{params[:dev]} || exit 1

        disktype #{params[:dev]} | awk 'BEGIN{ blank=0 }; /^--- /{getline; getline; if (/^Blank /) { blank=1 }}; END{ if (blank) { exit 2 }}'
        ret=$?
        if [ $ret -eq 2 ]; then
            echo y | mkfs -t ext3 -j #{params[:dev]}
        fi
        EOH
    end

    directory params[:mountpoint]

    mount params[:mountpoint] do
        device params[:dev]
        fstype "ext3"
    end
end

