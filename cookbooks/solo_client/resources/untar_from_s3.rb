require 'pathname'

actions :run

attribute :artifact, :kind_of => String, :name_attribute => true
attribute :container_path, :kind_of => [String, Pathname], :required => true
attribute :delete_dir_in_container, :kind_of => [String, Pathname]
attribute :user, :kind_of => String

def initialize(*args)
    super
    @action = :run
end

