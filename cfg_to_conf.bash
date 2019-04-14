#!/usr/bin/env bash
###############################################################################
# 
# These scripts have NOT been tested in a production environment. They were
# NOT written by a senior administrator or master bash/awk programmer.
# If somehow you stumbled into this repo from Google or something, turn
# back now and don't use this in your production environment.
#
# This bash script orchestrates a set of awk scripts to translate Nagios .cfg
# syntax into Icinga2 .conf syntax. 
#
# Note: the awk scripts make no attempt at pre-validating the files they read
# before processing them. This has the effect that feeding the same directory
# to multiple arguments will cause the same file to be read three times,
# twice by the Host translator and once by the Command translator. 
# It also has the effect that if your Nagios configuration is monolithic
# then the excessively large files you've used may actually be processed by
# the correct translators--but I guarantee the output will be VERY messy.
#
###############################################################################

####
# Exit code style guide:
# 1: generic error (because most programs return this on failure)
# 2: Missing resource
# 3: PEBKAC
####

####
# Usage
####

read -d '' usage <<'EOF'
Usage: cfg_to_conf.bash -c <cmd dir> -h <host dir> -t <templates dir>
(Not yet implemented: -f <file>)
Any ommited argument will default to the standard location used by Nagios,
i.e.: /usr/local/nagios/etc/{commands,hosts,templates}

EOF

####
# Handle signals
####

function say_grace {
    if [ -e "./translated_cmd.txt" ]; then
        rm ./translated_cmd.txt
    fi
    exit 3
}

trap "say_grace" SIGTERM SIGINT

####
# Get user input; make assumptions if the user is silent.
####

if [[ $# < 1 ]]; then echo "$usage" && exit 3; fi

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
            echo "$usage"
            exit 3
            ;;
    esac
    shift
done

cmd_dir=${cmd_dir:-/usr/local/nagios/etc/commands/}
hst_dir=${cmd_dir:-/usr/local/nagios/etc/hosts/}
tpl_dir=${cmd_dir:-/usr/local/nagios/etc/templates/}

dirs=("$cmd_dir" "$hst_dir" "$tpl_dir")

for dir in "${dirs[@]}"; do
    [ -d "${dir}" ] || {
        echo "Directory not found: ${dir}" 
        exit 2
    }
done

####
# Make sure our scripts exist
####

trans_cmd="translate_command.awk"
trans_hst="translate_host.awk"
itl_map="itl_map.awk"

scripts=("$trans_cmd" "$trans_hst" "$itl_map")

for script in "${scripts[@]}"; do
    [ -f "$(pwd)/${script}" ] || {
        echo "Missing awk script: ${script}" 
        exit 2
    }
done

####
# Warn the user we're about to dump a bunch of text to STDOUT
####

echo -e "This script writes to STDOUT!\nThis may flood your terminal if you forgot to pipe or redirect."
sleep 2

####
# Process the files
####

function find_cfg {
    declare -a files=($(find "${1}" -name "*cfg"))
    for file in ${files[@]}; do
        awk -f "$2" "$file"
        echo -e "\n\n"
    done
}

find_cfg $cmd_dir $trans_cmd | tee ./translated_cmd.txt
find_cfg $tpl_dir $trans_hst
find_cfg $hst_dir $trans_hst

rm ./translated_cmd.txt
