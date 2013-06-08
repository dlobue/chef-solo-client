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

# Consume data from ohai and attributes provided as JSON on the command line.
# Ohai data takes precedence over data provided in JSON file, but data in
# JSON file should take precendence over cookbooks. I had always assumed this
# was the way that chef worked. Turns out it didn't, so this fix is to make
# chef conform to my expectations.

class Chef::Node

  def consume_external_attrs(ohai_data, json_cli_attrs)
    Chef::Log.debug("Extracting run list from JSON attributes provided on command line")
    consume_attributes(json_cli_attrs)

    @automatic_attrs = Chef::Mixin::DeepMerge.merge(json_cli_attrs, ohai_data)

    platform, version = Chef::Platform.find_platform_and_version(self)
    Chef::Log.debug("Platform is #{platform} version #{version}")
    @automatic_attrs[:platform] = platform
    @automatic_attrs[:platform_version] = version
  end

end

