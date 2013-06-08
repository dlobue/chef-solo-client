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

