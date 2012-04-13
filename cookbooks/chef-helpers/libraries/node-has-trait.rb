
class Chef::Node
    def has_trait?(trait)
        [traits].flatten.include? trait
    end
end

