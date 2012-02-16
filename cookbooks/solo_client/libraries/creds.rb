
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
    #f = File.open(fname)
    #creds = Hash[f.map { |line| line.split("=").map { |str| str.strip() } }]
    #f.close()
    #return creds
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

