
name "begin"
description "recipes that should always run first."

run_list(
    "recipe[misc::apt_fix]",
    "recipe[misc::mounts]",
    "recipe[solo_client::auto_restart_chef]",
    "recipe[solo_client::apt]",
    "recipe[misc::default]",
    "recipe[solo_client::make_available]"
    "recipe[solo_client::last_call]"
)

