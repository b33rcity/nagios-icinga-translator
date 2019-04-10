#!/usr/bin/env awk

function split_args(command) {
    split(command, params, "!")
    check = params[1]
    for (i=2; i <= length(params); i++) {
        arg[i-1] = params[i]
    }
    start_check = 0 
    while ((getline < "./translated_cmd.txt") > 0) {
        if ($1 == "###" && $2 == check) {
            start_check = 1
        } else if ($1 == "###" && $2 != check) {
            start_check = 0
        }
        if (start_check == 1) { 
            switch($3) {
                case /ARG[[:digit:]]+/:
                    # Turn eg $ARG1$ into 1
                    match($3, /[[:digit:]]+/, arg_num)
                    idx = check arg_num[0]
                    attribute[idx] = $1 " " $2 " " arg[arg_num[0]]
                    continue
                case /true/:
                    idx = check "!" $1
                    attribute[idx] = $1 " " $2 " true"
                    continue
            }
        }
    }
    for (x in attribute) {
        print "    " attribute[x]
    }
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
            svc_check = ""
            for (f=2; f <= NF; f++) {
                if (f==2) {
                    svc_check = svc_check $f
                } else {
                    svc_check = svc_check " " $f
                }
            }
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
    print "\n    // I think this host needs these service attributes:"
    split_args(svc_check)
    print "\n/* Original cfg follows:\n *"
    for (i in original) {
        print " * " original[i]
    }
    print " */\n}"
}
