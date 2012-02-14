require 'pathname'

actions :run

attribute :artifact, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String

def initialize(*args)
    super
    @action = :run
end

