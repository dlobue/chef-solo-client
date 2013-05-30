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
# helper function to convert a human-readable string to an integer

def str_to_bytes(s)
    r = s.match(/^[0-9]+/)
    amount = r.to_s.to_i
    units = r.post_match

    units.each_char { |c|
        case c
        when "k", "K"
            amount *= (1024**1)
        when "m", "M"
            amount *= (1024**2)
        when "g", "G"
            amount *= (1024**3)
        when "b"
            amount /= 8
        when "B"
            amount /= 1
        end
    }
    return amount
end

