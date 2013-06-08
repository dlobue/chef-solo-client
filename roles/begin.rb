#
#   Copyright 2013 Geodelic
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License. 
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#

name "begin"
description "recipes that should always run first."

run_list(
    "recipe[misc::apt_fix]",
    "recipe[misc::mounts]",
    "recipe[solo_client::auto_restart_chef]",
    "recipe[solo_client::apt]",
    "recipe[misc::default]",
    "recipe[solo_client::begin_end_hub]"
)

