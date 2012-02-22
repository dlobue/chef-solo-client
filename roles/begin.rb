
name "begin"
description "recipes that should always run first."

run_list(
  "role[_begin]"
)

env_run_lists(
  "cloud" => [
    "role[_begin]",
    "recipe[misc::mounts]",
    "recipe[solo_client::auto_restart_chef]",
    "role[make_homey]"
  ]
)

