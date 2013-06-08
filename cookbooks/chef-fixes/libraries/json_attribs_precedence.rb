
# Consume data from ohai and attributes provided as JSON on the command line.
# Ohai data takes precedence over data provided in JSON file, but data in
# JSON file should take precendence over cookbooks. I had always assumed this
# was the way that chef worked. Turns out it didn't, so this fix is to make
# chef conform to my expectations.

class Chef::Node

  def consume_external_attrs(ohai_data, json_cli_attrs)
    Chef::Log.debug("Extracting run list from JSON attributes provided on command line")
    consume_attributes(json_cli_attrs)

    @automatic_attrs = Chef::Mixin::DeepMerge.merge(json_cli_attrs, ohai_data)

    platform, version = Chef::Platform.find_platform_and_version(self)
    Chef::Log.debug("Platform is #{platform} version #{version}")
    @automatic_attrs[:platform] = platform
    @automatic_attrs[:platform_version] = version
  end

end

