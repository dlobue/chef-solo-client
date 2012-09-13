
name "stop_services_on_fail"
description "stops all known services when a chef run fails"

default_attributes(
  "not_lockrable_trait_failstop" => [ "stop_services_on_fail" ]
)

override_attributes(
  "fail_stop" => {
    "enabled" => true
  }
)

run_list(
  "recipe[fail_stop::default]"
)

