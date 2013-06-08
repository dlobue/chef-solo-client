
if node.attribute?("make_homey") and node.make_homey
    #include_recipe "misc::distutils"
    include_recipe "misc::bashrc"
    include_recipe "misc::dotssh"
end

