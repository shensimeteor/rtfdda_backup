#!/bin/bash
#usage: backup_rtfdda.sh [-m "comments" ] [DIR1 [DIR2 ..]]

dest=/home11/ncar_fdda/rtfdda_backup/
GMIDS="GECN9KME"
prefix="$HOME"
do_git="True"
limit_mb="20" #only 

function get_all_dirs(){
    local prefix=$1
    local gmids=$2
    local all_dirs=""
    #GMODJOBS
    for gmid in $gmids; do
        dir_gmjb=$prefix/data/GMODJOBS/$gmid
        if [ -d $dir_gmjb ]; then
            all_dirs="$all_dirs $dir_gmjb"
        fi
    done
    #fddahome
    dir_fddahome=$prefix/fddahome
    if [ -d $dir_fddahome ]; then
        all_dirs="$all_dirs $dir_fddahome"
    fi
    echo "$all_dirs"
}

#$1 source_dir, $2: prefix_of_source, $3: prefix_of_dest
function get_dest_dirs(){
    local src_dirs=$1
    local pfx_src=$2
    local pfx_dest=$3
    local dest_dirs=""
    for dir in $src_dirs; do
        postfix_dir=${dir#$pfx_src}
        dest_dir=$pfx_dest/$postfix_dir
        dest_dirs="$dest_dirs $dest_dir"
    done
    echo $dest_dirs
}
        




narg=$#
declare -a args
args=($@)
comment="auto comment @ $(date +'%Y-%m-%d %H:%M:%S')"
dirs=""
for ((i=0;i<$narg;i++)); do
    this_arg=${args[$i]}
    if [ $this_arg == "-m" ]; then
        next_arg=${args[$(($i+1))]}
        if [ -z "$next_arg" ]; then
            echo "comment argument missing!"
            exit 2
        fi
        comment=next_arg
        i=$(($i+2))
    else
        #not support here
        echo "Do not support specifying dir yet!"
        exit 2
        if [ -d $this_arg ]; then
            this_dir=$(cd $this_arg && pwd)
            dir="$dirs $this_dir"
        else
            echo "dir: $this_arg missing!"
            exit 2
        fi
    fi
done

if [ -z "$dirs" ]; then
    dirs=$(get_all_dirs $prefix $GMIDS)
fi
echo $dirs
dest_dirs=$(get_dest_dirs "$dirs" $prefix $dest)
echo $dest_dirs



