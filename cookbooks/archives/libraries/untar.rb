#
#   Copyright 2013 Dominic LoBue
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
# resource for untarring archives.

require 'fileutils'
require 'pathname'

class Chef::Resource
  class UntarArchive < Chef::Resource::File
    def initialize(name, run_context=nil)
      super
      @resource_name = :untar_archive
      @provider = Chef::Provider::UntarArchive
      @delete_dir_in_container = nil
      @creates = nil
      @container_path = nil
      @nice = nil
    end

    def container_path(arg=nil)
      set_or_return(
        :container_path,
        arg,
        :kind_of => [ String, Pathname ]
      )
    end

    def creates(arg=nil)
      set_or_return(
        :creates,
        arg,
        :kind_of => [ String, Pathname ]
      )
    end

    def delete_dir_in_container(arg=nil)
      set_or_return(
        :delete_dir_in_container,
        arg,
        :kind_of => [ String, NilClass ]
      )
    end

    def nice(arg=nil)
      arg = arg.kind_of?(Numeric) ? arg.to_i : arg
      set_or_return(
        :nice,
        arg,
        :callbacks => { 
          "not in valid numeric range. must be an integer between -19 and 19" => lambda { |m| 
            if m.nil?
              true
            else
              m.kind_of?(Integer) && m >= -19 && m <= 19
            end
          }
        }
      )
    end

  end
end


class Chef::Provider
  class UntarArchive < Chef::Provider::File

    def action_create

      raise "archive missing!" unless ::File.exist? @new_resource.path

      createsPath = new_resource.creates.to_s.start_with?('/') ? new_resource.creates.to_s : ::File.join(new_resource.container_path, new_resource.creates)

      #extract block
      if not ::File.exists?(createsPath) or ::File.mtime(@new_resource.path) > ::File.mtime(createsPath)
        #TODO: ensure container path exists!
        #delete block
        to_remove = "#{new_resource.container_path}/#{new_resource.delete_dir_in_container}"
        if not new_resource.delete_dir_in_container.nil? and ::File.exists?(to_remove)
            Chef::Log.info("deleting dir_in_container: #{to_remove}")
            FileUtils.remove_dir( to_remove, true )
        end
        Chef::Log.info("untaring archive #{@new_resource.path} to #{new_resource.container_path}")

        decompressvar = case
                        when @new_resource.path.end_with?('bz2') then 'j'
                        when @new_resource.path.end_with?('gz') then 'z'
                        else ''
                        end

        if @new_resource.nice.nil?
          nicevar = ''
        else
          nicevar = "nice -n #{@new_resource.nice} -- "
        end
        #TODO: support --no-same-permissions and custom umask
        args = {:command => "#{nicevar}tar #{decompressvar}xf #{@new_resource.path} --no-same-owner --touch -C #{new_resource.container_path}"}
        args[:user] = @new_resource.owner if @new_resource.owner
        args[:group] = @new_resource.group if @new_resource.group

        begin
            Chef::Mixin::Command.run_command(args)
        rescue Chef::Exceptions::Exec => e
            ::File.rename( @new_resource.path, "#{@new_resource.path}.failed" )
            raise e
        end
        FileUtils.touch createsPath
        new_resource.updated_by_last_action(true)
      else
        new_resource.updated_by_last_action(false)
      end
    end
  end
end

Chef::Platform.platforms[:default].merge! :untar_archive => Chef::Provider::UntarArchive

