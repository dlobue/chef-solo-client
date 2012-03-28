
class Promise < Proc
    undef_method :instance_of?
    undef_method :is_a?
    undef_method :kind_of?
    undef_method :respond_to?
    undef_method :class
    undef_method :to_s
    undef_method :display
    def method_missing(method, *args, &block)
        call.send(method, *args, &block)
    end
end


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

