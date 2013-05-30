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
# lockr is a global semaphore. it takes advantage of the SimpleDB consistency enhancements released in 2010: http://aws.amazon.com/articles/3572  
# The part of the consistency enhancements that lockr uses is not far different from an SQL UPDATE statement. Before that, some background information:
# Each deployment gets its own item (like a record, or a document) in simpledb which is used for storing the state of the semaphore. In the semaphore document there is (among other things), a revision counter. Every time chef grabs the semaphore, it increases the revision counter.
# As I was saying, the way the semaphore works is by telling simpledb to update the record only if the revision counter is the same number it was the last time we looked. If the revision counter hasn't changed since the last time we looked, then grab the semaphore and increase the revision counter by one. Changing the revision counter causes the "UPDATE" command performed by other servers at the same time to fail.

class LockrError < RuntimeError
end

def _get_lockable_traits(node)
    ([node[:persist][:traits]].flatten) - (node.keys.select { |k|
          k.to_s != 'not_lockrable_traits' and k.to_s.start_with?('not_lockrable_trait')
    }.map { |k| node[k] }.flatten)

end

def _get_lock_list(node)
    lockable_traits = _get_lockable_traits(node)
    lock_list = Hash[lockable_traits.map {|trait| [trait, node[:persist][:fqdn]]}]
    [lockable_traits, lock_list]
end

def acquire_lockr(node)
    lockable_traits, lock_list = _get_lock_list(node)
    Chef::Log.debug("Just stating: lock_list is >#{lock_list.inspect}>")

    ratio_divisor = Chef::Config[:lockr_ratio_divisor] ? Chef::Config[:lockr_ratio_divisor] : 10

    trait_max = Hash[lock_list.map { |trait,fqdn|
        count = fakesearch(:traits => trait, :attributes => 'count(*)')/ratio_divisor
        [trait, (count >= 1 ? count : 1) ]}]
    Chef::Log.debug("Max number of locks that can be acquired for each trait: >#{trait_max.inspect}>")

    skip = false
    lock_list[:rev] = 0
    expects = {:expect => {:rev => false}}
    loop do
        begin
            if not skip
                Chef::Log.debug("Going to try to get the lock. lock_list is >#{lock_list.inspect}<, and expects is >#{expects.inspect}<")
                PersistWrapper._put(PersistWrapper.deployment, lock_list, expects)
                Chef::Log.info("Got the lock! continuing with the run.")
                break
            end
        rescue Excon::Errors::NotFound => e #404
        rescue Excon::Errors::Conflict => e #409
        end
        sleep 10 if lock_list[:rev] > 0 #so we don't sleep the first time through.
        got = PersistWrapper._get(PersistWrapper.deployment, [lockable_traits, :rev].flatten)
        rev = got.delete(:rev)
        expects = {:expect => {:rev => rev}, :replace => [:rev]}
        lock_list[:rev] = rev.to_i + 1

        sanity_test = [lockable_traits].flatten.map {|trait| [got[trait]].flatten.include? node[:persist][:fqdn]}
        if not (sanity_test.include? true) ^ (sanity_test.include? false)
            raise LockrError, "we've acquired the lock for some of our traits, but not all of them. this shouldn't be possible! lock looks like: #{got.inspect}"
        elsif sanity_test.include? true
            Chef::Log.info("We already have the lock. Proceeding with run.")
            break
        end
        maxed_out = Hash[got.select { |k,v| [v].flatten.length >= trait_max[k] }]
        if maxed_out.empty?
            skip = false
        else
            Chef::Log.info("The maximum number of locks for the traits #{maxed_out.keys.join(', ')} have already been acquired. waiting...")
            skip = true
        end
    end
end

def release_lockr(node)
    lockable_traits, lock_list = _get_lock_list(node)

    Chef::Log.info("Releasing the lock.")
    PersistWrapper._delete(PersistWrapper.deployment, lock_list)
end

