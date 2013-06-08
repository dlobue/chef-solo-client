#
#   Copyright 2013 Geodelic
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

def fakesearch_all_nodes(options = {})
    fakesearch_nodes(nil, options)
end

def fakesearch_node(nodeType, options = {})
    results = fakesearch_nodes(nodeType, options)
    if results.nil? or results.empty?
        nil
    elsif results.size > 1
        raise "Multiple nodes found with node-type: #{nodeType}, #{results.inspect}"
    else
        results[0]
    end
end

def fakesearch_nodes(nodeType, options = {})
    unless nodeType.nil? or (nodeType.kind_of? Array and nodeType.empty?)
        options[:traits] = nodeType
    end
    results = fakesearch(options)
    if results.respond_to? :map
        results = results.map { |result| Mash["persist" => result] }
    end
    return results
end

def fakesearch(options = {})
    options[:deployment] = PersistWrapper.deployment unless options.has_key? :deployment
    options[:attributes] = nil unless options.has_key? :attributes
    attributes = options.delete(:attributes)
    deployment = options.delete(:deployment)
    filters = []
    if deployment
        filters.push("deployment = '#{deployment}'")
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
    Chef::Log.debug("Fake-Searching query '#{filters.join(' and ')}'")
    results = PersistWrapper.search(filters.join(' and '), attributes)
    Chef::Log.debug("Fake-Search returned #{results.length} entries") if results.kind_of? Array
    return results
end

