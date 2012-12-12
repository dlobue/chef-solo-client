
include_recipe "solo_client::default"

cookbook_dir = Array(Chef::Config[:cookbook_path]).detect{|e| e =~ /\/cookbooks\/*$/ }

s3_file "creds" do
  only_if { node.attribute?("get_creds") and node.get_creds }
  action :create_artifact
  bucket node.env.s3_bucket
  folder node.env.s3_folder
  path (node.env.archive_dir + "#{name}.tgz").to_s
end

untar_archive "creds" do
  only_if { node.attribute?("get_creds") and node.get_creds }
  path (node.env.archive_dir + "#{name}.tgz").to_s
  container_path cookbook_dir
  creates File.join(cookbook_dir, 'cred_cookbook')
  notifies :create, "ruby_block[apply_creds]", :immediately
end

ruby_block "apply_creds" do
    action :nothing
    block do
        Chef::Log.info("Need to restart chef run to get new creds in node. Raising sigalrm!.")
        raise SignalException, "SIGALRM"
    end
end

