#!/bin/bash
#####
# Show changed packages in ctm
#####

git diff --name-only master... | grep / | awk 'BEGIN {FS="/"} {print $1 "/" $2}' | uniq
