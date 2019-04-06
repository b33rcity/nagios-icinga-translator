#!/usr/bin/env awk
@include "itl_map.awk"

# Create the attr variable using values in the itl_map array.
# This gets printed in the END block.
function mapper(check, flag) {
    attr = sprintf("vars.%s = ", itl_map[check][flag])
    if (typeof(commands[check][flag]) == "string") {
        attr = attr "\"" commands[check][flag] "\""
    } else {
        attr = attr commands[check][flag]
    }
    print attr
}

# Pass an array variable and a string version of the variable's name,
# and a mapping function. Declare check as a local variable.
function array_walk(arr, name, map, command,    check) {
    for (element in arr) {
        if (isarray(arr[element])) {
            check = arr[element]["name"]
            array_walk(arr[element], (name "[" element "]"), "mapper", check)
        } else if (element == "name") { 
            continue 
        } else {
            @map(command, element)
        }
    }
}

$1 ~ /^command_line/ {  
    cmd = $2
    for (i=3; i <= NF; i++) {
        if ($i ~ /-.{1}/) {
            if ($(i+1) !~ /-.{1}/) {
                arg[$i] = $(i+1)
            } else {
                arg[$i] = "true"
            }
        }
    }
    #print cmd ":"
    commands[cmd]["name"] = cmd
    for (x in arg) {
        # Build an array of arrays to contain each command and its args
        commands[cmd][x] = arg[x]
    }
    delete arg
    original[NR] = $0
}

END {
    printf "Commands from %s seem to be defined in this way: \n", FILENAME
    array_walk(commands, "commands", "mapper")
    print "\n/* Original command definition(s): "
    for (line in original) { print " * " original[line] }
    print " */"
}
