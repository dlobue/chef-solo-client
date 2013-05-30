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

