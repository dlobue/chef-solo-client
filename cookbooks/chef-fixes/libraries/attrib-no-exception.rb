
#tired of node[:non_existant_attribute] and node.non_existant_attribute having different functionality 
#the first will result in a nil, while the second will result in an exception.
class Chef::Node::Attribute
  alias _method_missing method_missing

  def method_missing(symbol, *args)
    begin
      _method_missing(symbol, *args)
    rescue ArgumentError => e
      if e.message == "Attribute #{symbol} is not defined!"
        return nil
      else
        raise e
      end
    end
  end
end

