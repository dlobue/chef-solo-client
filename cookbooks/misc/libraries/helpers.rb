
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

