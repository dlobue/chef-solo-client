
name "begin"
description "recipes that should always run first."

run_list(
    "recipe[apt::apt_fix]",
    "recipe[apt::default]",
    "recipe[misc::mounts]",
    "recipe[solo_client::auto_restart_chef]",
    "recipe[misc::default]",
    "recipe[solo_client::begin_end_hub]"
)

