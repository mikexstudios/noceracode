#!/bin/bash
# When run inside a directory, recursively searches sub-directories for:
# 1. tafel_combined.pdf and tafel_#.pdf files
# 2. tafel_combined_fit.pdf files
# These files are opened all in one Preview session to make it easy to print
# multiple plots one one page.

#This first line finds all files of either tafel_combined.pdf or tafel_#.pdf.
#Then it excludes (using the !) the old/ and combined/ paths.
#We pass the multi-line output into xargs to combine it all into one line
#We then pass the whole line into open to invoke Preview
find -E . \( -regex '.+/tafel_combined.pdf' -o -regex '.+/tafel_[0-9]+.pdf' \) \! -path './old/*' \! -path './combined/*' \
| xargs \
| xargs open

find -E . -regex '.+/tafel_combined_fit.pdf' \! -path './old/*' \! -path './combined/*' \
| xargs \
| xargs open
