#!/bin/bash
if [ -z $1 ]
then
    echo 'Usage: $0 [number]'
    exit
fi

FILES=`ls cp*_$1.txt`
for f in $FILES
do
    echo "Filename: $f"
    cp_convergence $f
    echo
done
