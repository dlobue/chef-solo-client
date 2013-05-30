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

define :format_and_mount, :dev => nil, :mountpoint => nil do
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

