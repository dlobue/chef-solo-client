#
#   Copyright 2013 Geodelic
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
# Rolr was the precursor to Lockr. It is essentially a queue. It is kept around
# for historical reasons, and because it may one day be useful again since it
# is not susceptible to lock starvation.

class RolrError < RuntimeError
end

class Rolr
    def initialize(node)
        @node = node
    end

    def _isNodeDirty?(node)
        if (((node[:persist][:dirty_stamp] == nil) ^ (node[:persist][:activity] == nil)) or
            ((node[:persist][:state] == 'dirty') and (node[:persist][:dirty_stamp] == nil))) then
            raise RolrError, "Invalid dirty state"
        end
        not node[:persist][:dirty_stamp] == nil
    end

    def acquire(activity)
        if @node[:persist][:state]=="pending"
            return true
        end
            
        if _isNodeDirty?(@node)
            if @node[:persist][:activity] == activity
                return true
            else
                return false
            end
        end

        @node[:persist][:state] = 'dirty'
        @node[:persist][:activity] = activity
        @node[:persist][:dirty_stamp] = Time.now.to_f
        return true
    end

    def _dirty_node_info
        r = @_dirtyNodes.map { |n|
            "#{n[:persist][:dirty_stamp]}__#{n[:persist][:fqdn]}"
        }
        return r.join(", ")
    end

    def clearedToShutdown?()
    #def cleared_check(activity)
        if @node[:persist][:state]=="pending"
            return true
        end
            
        if not _isNodeDirty?(@node)
            #Chef::Log.info("Server is not dirty, and not cleared to shutdown.")
            return false
        end

        # cache the list of dirtyStamps
        if @_dirtyNodes.nil?
            @_dirtyNodes = fakesearch_nodes(@node[:persist][:traits],
                                            :state => 'dirty',
                                            :activity => @node[:persist][:activity])
            @_dirtyNodes.sort! { |x,y|
                x[:persist][:dirty_stamp] <=> y[:persist][:dirty_stamp]
            }
            Chef::Log.info("other dirty stamps: #{_dirty_node_info}")
        end

        if @_dirtyNodes.empty?
            return false
        end

        oldest_stamp = @_dirtyNodes[0][:persist][:dirty_stamp].to_f
        _now = Time.now.to_f
        if oldest_stamp < (_now - 3600)
            Chef::Log.warn("Found dirty stamps older than an hour.")
        elsif oldest_stamp < (_now - (3600 * 4))
            Chef::Log.error("Found dirty stamps older than four hours.")
        elsif oldest_stamp < (_now - (3600 * 8))
            Chef::Log.critical("Found dirty stamps older than eight hours.")
        end

        verdict = @_dirtyNodes[0][:persist][:fqdn] == @node[:persist][:fqdn]

        if verdict
            Chef::Log.info("Node is cleared to perform activity.")
        else
            Chef::Log.info("Node is NOT cleared to perform activity. Rolr order: #{_dirty_node_info}")
        end
        
        return verdict
    end

    def clean(cleaned_state = 'clean')
        Chef::Log.info("Cleaning node's dirty stamp and setting state to available.")
#        @node[:persist].update( :dirty_stamp => nil,
#                            :activity => nil,
#                            :state => cleaned_state
#        )
        @_dirtyNodes = nil
        @node[:persist][:dirty_stamp] = nil
        @node[:persist][:activity] = nil
        @node[:persist][:state] = cleaned_state
    end

end

