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

def fakesearch_all_nodes(options = {})
    fakesearch_nodes(nil, options)
end

def fakesearch_nodes(nodeType, options = {})
    options[:deployment] = PersistWrapper.deployment unless options.has_key? :deployment
    options[:attributes] = nil unless options.has_key? :attributes
    deployment = options.delete(:deployment)
    attributes = options.delete(:attributes)
    filters = []
    if deployment
        filters.push("deployment = '#{deployment}'")
    end
    if nodeType
        if nodeType.kind_of? Array
            nTq = (nodeType.map { |v| "traits = '#{v}'" }).join(" intersection ")
        else
            nTq = "traits = '#{nodeType}'"
        end
        filters.push(nTq)
    end
    if not options.empty?
        options.each do |key,val|
            if val.kind_of? Array
                nTq = (val.map { |v| "#{key} = '#{v}'" }).join(" intersection ")
            elsif val == "*"
                nTq = "#{key} is not null"
            else
                nTq = "#{key} = '#{val}'"
            end
            filters.push(nTq)
        end
    end
    Chef::Log.debug("Fake-Searching #{nodeType} with query '#{filters.join(' and ')}'")
    results = PersistWrapper.search(filters.join(' and '), attributes)
    Chef::Log.debug("Fake-Searching #{nodeType} returned #{results.length} entries") if results.kind_of? Array
    return results
end

def fakesearch_node(nodeType, options = {})
    results = fakesearch_nodes(nodeType, options)
    if results.empty?
        nil
    elsif results.size > 1
        raise "Multiple nodes found with node-type: #{nodeType}, #{results.inspect}"
    else
        results[0]
    end
end

