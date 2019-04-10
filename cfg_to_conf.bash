#!/usr/bin/env bash

####
# Exit code style guide:
# 1: generic error (because most programs return this on failure)
# 2: Missing resource
# 3: PEBKAC
####

####
# Get user input; make assumptions if the user is silent.
####

while [[ "$1" != "" ]]; do
    case $1 in
        -c | --commands )
            shift
            cmd_dir=$1
            ;;
        -h | --hosts )
            shift 
            hst_dir=$1
            ;;
        -t | --templates )
            shift
            tpl_dir=$1
            ;;
        -f | --file )
            shift
            one_file=$1
            single=0
            ;;
        * )
            echo "unhelpful help text"
            exit 3
            ;;
    esac
    shift
done

cmd_dir=${cmd_dir:-/usr/local/nagios/etc/commands/}
hst_dir=${cmd_dir:-/usr/local/nagios/etc/hosts/}
tpl_dir=${cmd_dir:-/usr/local/nagios/etc/templates/}

dirs=("$cmd_dir" "$hst_dir" "tpl_dir")

pat='^.*;+.*$'
for dir in ${dirs[@]}; do 
    if [[ $dir =~ $pat ]]; then
        echo -e "What is this?? ${dir}\n*Shell injection*???\nGTFO"
        exit 3
    elif [[ $dir =~ .*&&.* ]]; then
        echo -e "What is this?? ${dir}\n*Shell injection*???\nGTFO"
        exit 3
    elif [[ $dir =~ .*||.* ]]; then
        echo -e "What is this?? ${dir}\n*Shell injection*???\nGTFO"
        exit 3
    fi
done

[ -n $one_file ] && [[ $one_file =~ (.*;.*|.*&&.*|.*\|\|.*) ]] &&\
    echo -e "What is this?? ${dir}\n*Shell injection*???\nGTFO" && exit 3

####
# Make sure our scripts exist
####

trans_cmd="translate_command.awk"
trans_hst="translate_host.awk"
itl_map="itl_map.awk"

scripts=("$trans_cmd" "$trans_hst" "$itl_map")

for script in "${scripts[@]}"; do
    [ -e "$(pwd)/${script}" ]
    if [[ $? != 0 ]]; then
        echo "Missing awk script: ${script}" 
        exit 2
    fi
done
