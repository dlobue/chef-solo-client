
name "cloud"
description "recipes that should always be run in the cloud"

run_list(
  "recipe[solo_client::creds]",
  "role[_begin]",
  "recipe[misc::mounts]",
  "recipe[solo_client::auto_restart_chef]",
  "role[make_homey]"
)

