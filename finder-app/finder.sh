#!/bin/sh


# Accepts the following runtime arguments: the first argument is a path to a
# directory on the filesystem, referred to below as filesdir; 
# the second argument is a text string which will be searched
# within these files, referred to below as searchstr
filesdir=$1
searchstr=$2

if [ "$#" -ne 2 ]
then
    echo "ERROR: Wrong number of arguments"
    exit 1
fi

if [ ! -d $1 ]
then
    echo "File path not found"
    exit 1
fi

numfiles=$(find $filesdir -type f | wc -l)
nummatch=$(grep -r $searchstr $filesdir | wc -l)

echo "The number of files are $numfiles and the number of matching lines are $nummatch"