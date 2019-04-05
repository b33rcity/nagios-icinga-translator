#!/usr/bin/env awk

# First attempt to generalize the parsing of check_command
function split_args(command) {
    split(command, params, "!")
    for (i = 1; i < length(params); i++) {
        split(params[i], vals, ",")
    }
}

BEGIN {
    attribute = "    vars.%s = %s"
}

$1 == "define" {
    gsub(/{/, "", $2)
    type = toupper(substr($2,1,1)) substr($2,2,length($2))
}

# A "}" or a "}" followed by any spaces and a comment
$1 ~ /}$|}[ ]*#.*$/ {
    type = "None"
}

type == "Host" {
    switch($1) {
        case /host_name/:
            hst_name = $2
            original[NR] = $0
            next
        case /alias/:
            hst_display_name = $2
            original[NR] = $0
            next
        case /address/:
            hst_addr = $2
            original[NR] = $0
            next
        case /hostgroups/:
            hst_groups = "[ \"" gensub(",", "\", \"", g, $2) "\" ]"
            original[NR] = $0
            next
        case /check_command/:
            hst_check = $2
            original[NR] = $0
            next
        case /event_handler/:
            hst_event = $2
            original[NR] = $0
            next
        default:
            original[NR] = $0
            next
    }
}

type == "Service" {
    switch($1) {
        case /service_description/:
            svc_name = $2
            original[NR] = $0
            next
        case /display_name/:
            svc_display_name = $2
            original[NR] = $0
            next
        case /check_command/:
            svc_check = $2
            original[NR] = $0
            next
        case /event_handler/:
            svc_event = $2
            original[NR] = $0
            next
        default:
            original[NR] = $0
            next
    }
}

# Ignore commented lines
$1 ~ /^#/ { next }

{
    original[NR] = $0
}

END {
    print "object Host \"" hst_name "\" {"
    print "    import \"generic-host\""
    print "    address = \"" hst_addr "\""
    print "    check_command = \"" hst_check "\""
    if (display_name) {
        print "display_name = \"" hst_display_name "\""
    }
    if (event) {
        print "    event_command = \"" hst_event "\""
    }
    if (groups) {
        print "groups += " hst_groups
    }
    print "\n// I think this host needs these service attributes:"
    split(svc_check, cmd, "!")
    if (cmd[1] ~ /.*disk/) {
        for (i = 2; i <= length(cmd); i++) {
            if (cmd[i] ~ /\/[a-zA-Z\/]*/) {
                split(cmd[i], parts, ",")
                if (length(parts) > 1) {
                    sep = "\", "
                    joined = "[ \""
                    for (part = 1; part <= length(parts); part++) {
                        joined = joined parts[part] sep
                    }
                    partitions = joined "]"
                } else {
                    partitions = "\"" parts[1] "\""
                }
            }
            if (cmd[i] ~ /.*,[^,]*/) {
                split(cmd[i], wct, ",")
                warn = wct[1]
                crit = wct[2]
            }
            #out_arr[out_line] = sprintf(attribute, disk_attr[i], "\"" cmd[i] "\"")
        }
        printf(attribute, "disk_wfree", warn)
        print ""
        printf(attribute, "disk_cfree", crit)
        print ""
        printf(attribute, "disk_partitions", partitions)
        print ""
    }
    print blah
    print "\n/* Original cfg follows:\n *"
    for (i in original) {
        print " * " original[i]
    }
    print " */\n}"
}
