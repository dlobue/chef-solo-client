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

#tired of node[:non_existant_attribute] and node.non_existant_attribute having different functionality 
#the first will result in a nil, while the second will result in an exception.
class Chef::Node::Attribute
  alias _method_missing method_missing

  def method_missing(symbol, *args)
    begin
      _method_missing(symbol, *args)
    rescue ArgumentError => e
      if e.message == "Attribute #{symbol} is not defined!"
        return nil
      else
        raise e
      end
    end
  end
end

