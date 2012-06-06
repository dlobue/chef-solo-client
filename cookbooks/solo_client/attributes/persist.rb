
include_attribute "solo_client::default"

if attribute?("do_multi") and do_multi
    persist PersistentMash.new(PersistWrapper.new(FogSimpleDBWrapper.new(sdb_domain, fqdn, ec2.region), deployment))
    persist[:ec2_public_hostname] = ec2[:public_hostname] unless (persist[:ec2_public_hostname] == ec2[:public_hostname])
    persist[:ec2_instance_id] = ec2[:instance_id] unless (persist[:ec2_instance_id] == ec2[:instance_id])
    persist[:ec2_region] = ec2[:region] unless (persist[:ec2_region] == ec2[:region])
else
    persist Mash.new()
end

persist[:state] ||= 'pending'
persist[:deployment] = deployment unless (persist[:deployment] == deployment)
persist[:traits] = traits unless (persist[:traits] == traits)

persist[:started] ||= Time.now.to_f.to_s
persist[:fqdn] ||= fqdn

persist[:ec2_public_hostname] ||= "localhost"

