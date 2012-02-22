
name "_begin"
description "recipes that should always run first."

run_list(
    "recipe[apt::apt_fix]",
    "recipe[apt::default]",
    "recipe[solo_client::begin_end_hub]"
)

