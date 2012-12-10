# Computes the expression it was initialized with only when it is needed.
# acts like the resulting value of that expression, and should pretend to be of
# the resulting value type.
# used like so:
# foo = 'one'
# bar = 'two'
# s = Promise.new { foo + bar }
# s.to_s # results in the string 'onetwo'
# foo = 'three'
# bar = 'four'
# s.to_s # results in the string 'threefour'

class Promise < Proc
    undef_method :instance_of?
    undef_method :is_a?
    undef_method :kind_of?
    undef_method :respond_to?
    undef_method :nil?
    undef_method :class
    undef_method :to_s
    undef_method :display
    def method_missing(method, *args, &block)
        call.send(method, *args, &block)
    end
end

