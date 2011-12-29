
include_attribute "solo_client::default"

if attribute?("envswitch") and envswitch == "development"
    persist Mash.new()
else
    persist PersistentMash.new(PersistWrapper.new(FogSimpleDBWrapper.new("chef", fqdn, ec2.region), rs_deployment))
    persist[:ec2_public_hostname] = ec2[:public_hostname] unless (persist[:ec2_public_hostname] == ec2[:public_hostname])
    persist[:ec2_instance_id] = ec2[:instance_id] unless (persist[:ec2_instance_id] == ec2[:instance_id])
    persist[:ec2_region] = ec2[:region] unless (persist[:ec2_region] == ec2[:region])
    persist[:mounts] = [root_dir]
end

persist[:state] ||= 'pending'
persist[:deployment] = rs_deployment unless (persist[:deployment] == rs_deployment) #TODO: change me
persist[:traits] = traits unless (persist[:traits] == traits)

persist[:fqdn] ||= fqdn

persist[:ec2_public_hostname] ||= "localhost"

