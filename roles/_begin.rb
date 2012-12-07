
name "_begin"
description "recipes that should always run first."

run_list(
    "recipe[apt::apt_fix]",
    "recipe[apt::recommends]",
    "recipe[apt::s3repo]",
    "recipe[upstart::fix_logging]",
    "recipe[misc::mounts]",
    "recipe[solo_client::default]",
    "recipe[solo_client::begin_end_hub]"
)

