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
# use the DSL methods to load attribute files so we can be sure that each
# attribute file is loaded only once. Loading attribute files twice has caused
# problems in the past when I do tricky things.

class Chef::Node

  # Load all attribute files for all cookbooks associated with this
  # node.
  def load_attributes
    cookbook_collection.values.each do |cookbook|
      cookbook.attribute_filenames_by_short_filename.keys.each do |attribute_name|
        include_attribute "#{cookbook.name}::#{attribute_name}"
      end
    end
  end

end

