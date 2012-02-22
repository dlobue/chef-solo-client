
name "make_homey"
description "recipes to make things more home-like"

run_list(
    "misc::bashrc",
    "misc::dotssh"
)

