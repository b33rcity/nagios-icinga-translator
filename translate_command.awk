#!/usr/bin/env awk
@include "itl_map.awk"

# Create the attr variable using values in the itl_map array.
# This gets printed in the END block.
function mapper(check, flag) {
    attr = sprintf("vars.%s = ", itl_map[check][flag])
    if (typeof(commands[check][flag]) == "string") {
        # Don't quote bool or pre-quoted values
        if (commands[check][flag] == "true" || commands[check][flag] ~ /^".*"$/) {
            attr = attr commands[check][flag] 
        # Quote everything else
        } else {
            attr = attr "\"" commands[check][flag] "\""
        }
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
            print "### " check
            array_walk(arr[element], (name "[" element "]"), "mapper", check)
        } else if (element == "name") { 
            continue 
        } else {
            @map(command, element)
        }
    }
}

function parse_command(line) {
    cmd = $2
    for (i=3; i <= NF; i++) {
        # Match -X options
        if ($i ~ /^-[^- ]/) {
            if ($(i+1) !~ /^-.+/) {
                arg[$i] = $(i+1)
            } else {
                arg[$i] = "true"
            }
        # Match --word options (true/false type)
        } else if ($i ~ /^--[^ =]+$/) {
            arg[$i] = "true"
        # Match --word="xyz" and --word=123 options
        } else if ($i ~ /^--[^ =]+=.+/) {
            # cat fields that were split inside a quote
            if ($i ~ /[^"]*"[^"]+$/) {
                opt = $i " " $(i+1)
            } else {
                opt = $i
            }
            split(opt, val, "=")
            arg[val[1]] = val[2]
        }
    }
    commands[cmd]["name"] = cmd
    for (x in arg) {
        # Build an array of arrays to contain each command and its args
        commands[cmd][x] = arg[x]
    }
    delete arg
}

$1 ~ /^command_line/ {  
    parse_command($0)
    original[NR] = $0
}

END {
    printf "// Commands from %s seem to be defined in this way: \n", FILENAME
    array_walk(commands, "commands", "mapper")
    print "\n/* Original command definition(s): "
    for (line in original) { print " * " original[line] }
    print " */"
}
