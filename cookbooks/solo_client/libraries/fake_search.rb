
def fakesearch_all_nodes(options = {})
    fakesearch_nodes(nil, options)
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

def fakesearch_nodes(nodeType, options = {})
    unless nodeType.nil? or nodeType.kind_of? Array and nodeType.empty?
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
    filters = []
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

