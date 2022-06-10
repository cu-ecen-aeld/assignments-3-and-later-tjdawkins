#!/bin/sh

# Accepts the following arguments: the first argument is a full path to a file (including filename)
# on the filesystem, referred to below as writefile; the second argument is a text string which will
# be written within this file, referred to below as writestr

writefile=$1
writestr=$2

if [ "$#" -ne 2 ]
then
    echo "ERROR: Wrong number of arguments"
    exit 1
fi

path=$(dirname $writefile)
file=$(basename $writefile)

if [ ! -d $path ]
then
    mkdir -p $path
fi

echo $writestr > $writefile

if [ ! -f $writefile ]
then 
    echo "ERROR: Cannot create file"
    exit 1
fi
