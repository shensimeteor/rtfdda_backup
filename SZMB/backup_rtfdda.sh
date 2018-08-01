#!/bin/bash
#2017.4.21 update, read rsync-exclude_$GMID.txt
#usage: backup_rtfdda.sh [-m "comments" ] 

dest=/data04/fdda/rtfdda_backup/
test -d $dest || mkdir -p $dest
GMIDS="GWRUPPS GWRUNC GWSZ3H"
prefix="$HOME"
do_git=1
limit_size="5m" #only 

#$1: pwd, $2: $0 of this script
function mydir(){
    local is_begin_slash mydir
    is_begin_slash=$(echo $2 | grep "^/")
    if [ -n "$is_begin_slash" ]; then
        mydir=$(dirname $2)
    else
        mydir="$1"/$(dirname $2)
    fi
    echo $mydir
}

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
this_dir=$(mydir $(pwd) $0)
for ((i=0;i<$ndir;i++)); do
    cd $this_dir
    test -d ${arr_dst_dirs[$i]} || mkdir -p ${arr_dst_dirs[$i]}
    dir_title=$(basename ${arr_src_dirs[$i]})
    file_exclude="rsync_exclude_${dir_title}.txt"
    if [ -e $file_exclude ]; then
        rsync -avrz --max-size="$limit_size" --exclude-from "$file_exclude" ${arr_src_dirs[$i]}/* ${arr_dst_dirs[$i]}
    else
        rsync -avrz --max-size="$limit_size" ${arr_src_dirs[$i]}/* ${arr_dst_dirs[$i]}
    fi
    if [ $? -eq 0 ] && [ $do_git -eq 1 ]; then
        cd ${arr_dst_dirs[$i]}
        if [ ! -d ".git" ]; then
            git init .
        fi
        git add * 
	git commit -m "$comment"
   fi
done

