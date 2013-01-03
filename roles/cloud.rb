
name "cloud"
description "recipes that should always be run in the cloud"

default_attributes(
  "not_lockrable_trait_cloud" => [ "cloud" ]
)

run_list(
  "recipe[misc::mounts]",
  "recipe[solo_client::creds]",
  "role[begin]",
  "recipe[timezone::default]",
  "recipe[solo_client::update_ssh_authkeys]",
  "recipe[solo_client::auto_restart_chef]",
  "recipe[solo_client::delete_prep]",
  "role[make_homey]"
)

