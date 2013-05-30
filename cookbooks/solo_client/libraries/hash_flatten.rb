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

def flatten_hash(item, parent_name=nil, result=nil)
    result = Hash.new() if result.nil?
    if item.kind_of? Hash
        parent_name += "." if not parent_name.nil?
        item.each do |k,v|
            flatten_hash(v, "#{parent_name}#{k}", result)
        end
    else
        result[parent_name] = item
    end
    result
end

def _deep_update(dest, src)
    src.each do |k,v|
        if dest.has_key? k
            _deep_update(dest[k], v)
        else
            dest[k] = v
        end
    end
    dest
end

def expand_hash(item)
    result = Hash.new()
    item.each do |flat_key,value|
        flat_key.split('.').reverse.each do |sub_key|
            value = {sub_key => value}
        end
        _deep_update(result, value)
    end
    result
end

