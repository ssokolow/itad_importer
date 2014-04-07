#!/bin/bash
#
# Run this script after installing the release version of the userscript
#
# Requires:
# - npm install -g coffee-script coffeelint coffee-jshint docco
#
# TODO: Look into rewriting this as a Cakefile so I can use:
# - The same output colorization mechanism as CoffeeLint
# - A simpler option than shell for watching all installed copies of the script

# Make sure our relative paths are OK
cd "`dirname \"$0\"`"

printf "Running CoffeeScript compiler to watch for changes and update in-browser Javascript\n"
printf "Press Ctrl+C to exit and rebuild repository copy\n\n"
for X in ~/.mozilla/firefox/*/gm_scripts/IsThereAnyDeal.com_Collection_Importer/; do
    coffee -cwb -o "$X" itad_importer.user.coffee
    break # Trick to just get the first match
done

printf "\n\nRunning CoffeeLint...\n"
coffeelint itad_importer.user.coffee
printf "Running JSHint...\n"
coffee-jshint --options loopfunc,browser,devel,jquery itad_importer.user.coffee

printf "\nRunning CoffeeScript Compiler for Repository Build...\n"
coffee -cb itad_importer.user.coffee


printf "\nRunning docco to rebuild code documentation...\n"
docco itad_importer.user.coffee
