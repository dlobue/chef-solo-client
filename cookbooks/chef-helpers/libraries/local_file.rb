# Resource that adds the capability to copy files on top of what the file
# resource can already do natively.

class Chef::Resource
  class LocalFile < Chef::Resource::File
    def initialize(name, run_context=nil)
      super
      @resource_name = :local_file
      @provider = Chef::Provider::LocalFile
      @source = nil
    end

    def source(args=nil)
      set_or_return(
        :source,
        args,
        :kind_of => String
      )
    end
  end
end


class Chef::Provider
  class LocalFile < Chef::Provider::RemoteFile

    def action_create
      assert_enclosing_directory_exists!

      Chef::Log.debug("#{@new_resource} checking for changes")

      if current_resource_matches_target_checksum?
        Chef::Log.debug("#{@new_resource} checksum matches target checksum (#{@new_resource.checksum}) - not updating")
      else
        ::File.open(@new_resource.source) do |raw_file|
          if matches_current_checksum?(raw_file)
            Chef::Log.debug "#{@new_resource} target and source checksums are the same - not updating"
          else
            backup_new_resource
            FileUtils.cp raw_file.path, @new_resource.path
            Chef::Log.info "#{@new_resource} updated"
            @new_resource.updated_by_last_action(true)
          end
        end
      end
      enforce_ownership_and_permissions

      @new_resource.updated_by_last_action?
    end
  end
end


Chef::Platform.platforms[:default].merge! :local_file => Chef::Provider::LocalFile

