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


def get_indent(lvl, indent)
    "#{' ' * indent}|" * lvl
end

def get_indent2(lvl, indent)
    ' ' * (lvl * indent)
end

def deep_inspect(item, lvl = 0, indent = 2)
    if item.kind_of? Array
        puts "#{get_indent(lvl, indent)}["
        lvl += 1
        item.each do |i|
            if i.kind_of? Array or i.kind_of? Hash
                deep_inspect(i, lvl, indent)
            else
                puts "#{get_indent(lvl,indent)}#{i}"
            end
        end
        lvl -= 1
        puts "#{get_indent(lvl, indent)}]"
    elsif item.kind_of? Hash
        puts "#{get_indent(lvl, indent)}{"
        lvl += 1
        item.each do |k,v|
            if v.kind_of? Array or v.kind_of? Hash
                puts "#{get_indent(lvl,indent)}#{k} =>"
                deep_inspect(v, (lvl + 1), indent)
            else
                puts "#{get_indent(lvl,indent)}#{k} => #{v}"
            end
        end
        lvl -= 1
        puts "#{get_indent(lvl, indent)}}"
    end
end


def deep_inspects(item, lvl = 0, indent = 2)
    concat_str = ''
    if item.kind_of? Array
        concat_str << "#{get_indent(lvl, indent)}["
        concat_str << "\n"
        lvl += 1
        item.each do |i|
            if i.kind_of? Array or i.kind_of? Hash
                concat_str << deep_inspect(i, lvl, indent)
            else
                concat_str << "#{get_indent(lvl,indent)}#{i}"
            end
            concat_str << "\n"
        end
        lvl -= 1
        concat_str << "#{get_indent(lvl, indent)}]"
    elsif item.kind_of? Hash
        concat_str << "#{get_indent(lvl, indent)}{"
        concat_str << "\n"
        lvl += 1
        item.each do |k,v|
            if v.kind_of? Array or v.kind_of? Hash
                concat_str << "#{get_indent(lvl,indent)}#{k} =>"
                deep_inspect(v, (lvl + 1), indent)
            else
                concat_str << "#{get_indent(lvl,indent)}#{k} => #{v}"
            end
            concat_str << "\n"
        end
        lvl -= 1
        concat_str << "#{get_indent(lvl, indent)}}"
    end
    concat_str << "\n"
end

