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
# this library is an attempt to support any credential file format I may come across.

def get_creds
    begin
        _get_boto_creds
    rescue Errno::ENOENT => e
        _get_telegraph_creds
    end
end

def _get_telegraph_creds

    keymap = {
        "s3_access_key" => :aws_access_key_id,
        "s3_secret_key" => :aws_secret_access_key
    }

    fname = "/root/.telegraph.cfg"
    Hash[
        File.open(fname) { |f|
            f.map { |line|
                line.split("=").map { |str| str.strip() }
            }.map { |k,v| [keymap[k], v] }
        }
    ]
end

def _get_boto_creds
    fname = ENV.has_key?("BOTO_CONFIG") ? ENV["BOTO_CONFIG"] : "/root/.boto"
    Hash[
        File.open(fname) { |f|
            f.grep(/^aws[^=]+access_key[^=]*=/).map { |l|
                l.split("=").map { |str| str.strip() }
            }.map { |k,v| [k.to_sym, v] }
        }
    ]
end

