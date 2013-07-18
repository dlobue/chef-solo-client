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
# Computes the expression it was initialized with only when it is used.
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
  instance_methods.each do |m|
    undef_method(m) if m.to_s !~ /^__|^call$|^new$|^pretty/
  end
  def method_missing(method, *args, &block)
    call.send(method, *args, &block)
  end
end

