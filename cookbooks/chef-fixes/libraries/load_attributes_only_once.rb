
class Chef::Node

  # Load all attribute files for all cookbooks associated with this
  # node.
  def load_attributes
    cookbook_collection.values.each do |cookbook|
      cookbook.attribute_filenames_by_short_filename.keys.each do |attribute_name|
        include_attribute "#{cookbook.name}::#{attribute_name}"
      end
    end
  end

end

