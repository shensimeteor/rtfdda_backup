#!/bin/bash
#usage: backup_rtfdda.sh [-m "comments" ] [DIR1 [DIR2 ..]]

dest=/data0/rtfdda_backup/int2
test -d $dest || mkdir -p $dest
GMIDS="GE8CPI3E"
prefix="$HOME"
do_git=1
limit_size="5m" #only 

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
	post_dir=${dir#$pfx_src}
	dest_dir="${pfx_dest}/${post_dir}"
        dest_dirs="$dest_dirs $dest_dir"
    done
    echo $dest_dirs
}
        




narg=$#
declare -a args
args=($@)
comment="auto comment @ $(date '+%Y-%m-%d %H:%M:%S')"
dirs=""
for ((i=0;i<$narg;i++)); do
    this_arg=${args[$i]}
    if [ $this_arg == "-m" ]; then
        next_arg="${args[$(($i+1))]}"
        if [ -z "$next_arg" ]; then
            echo "comment argument missing!"
            exit 2
        fi
        comment="$next_arg"
        i=$(($i+2))
    else
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
dest_dirs=$(get_dest_dirs "$dirs" $prefix $dest)

declare -a arr_src_dirs
declare -a arr_dst_dirs
arr_src_dirs=($dirs)
arr_dst_dirs=($dest_dirs)
ndir=${#arr_src_dirs[@]}
echo $ndir
wd=$(pwd)
for ((i=0;i<$ndir;i++)); do
    test -d ${arr_dst_dirs[$i]} || mkdir -p ${arr_dst_dirs[$i]}
    rsync -avrz --max-size="$limit_size" ${arr_src_dirs[$i]}/* ${arr_dst_dirs[$i]}
    if [ $? -eq 0 ] && [ $do_git -eq 1 ]; then
        cd ${arr_dst_dirs[$i]}
        if [ ! -d ".git" ]; then
            git init .
        fi
        git add * 
	git commit -m "$comment"
   fi
done

