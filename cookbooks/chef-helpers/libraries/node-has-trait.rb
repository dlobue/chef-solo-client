# I found myself using the below snippet a lot, so I turned it into a function
# to make recipes clearer and easier to read.

class Chef::Node
    def has_trait?(trait)
        [traits].flatten.include? trait
    end
end

