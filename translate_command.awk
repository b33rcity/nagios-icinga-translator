#!/usr/bin/env awk

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

BEGIN {
    itl_map["check_http"]["-H"] = "http_address"
    itl_map["check_http"]["-I"] = "http_vhost"
    itl_map["check_http"]["-w"] = "http_warn"
    itl_map["check_http"]["-c"] = "http_crit"
    itl_map["check_http"]["-s"] = "http_ssl"
    itl_map["check_snmp"]["-H"] = "snmp_host"
    itl_map["check_snmp"]["-C"] = "snmp_community"
    itl_map["check_snmp"]["-o"] = "snmp_oid"
    itl_map["check_snmp"]["-w"] = "snmp_warn"
    itl_map["check_snmp"]["-c"] = "snmp_crit"
    helper_array[1] = "\n"
}

$1 ~ /[^#]command_line/ {
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
        #print "    " x ": " arg[x]
        # Build an array of arrays to contain each command and its args
        commands[cmd][x] = arg[x]
        # This also means I don't have to worry about multiple defs in one file.
    }
    delete arg
    original[NR] = $0
}

END {
    printf "Commands from %s seem to be defined in this way: \n", FILENAME
    array_walk(commands, "commands", "mapper")
    print "\n/* Original command line(s): "
    for (line in original) { print " * " original[line] }
    print " */"
}
