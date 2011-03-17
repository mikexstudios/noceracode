#!/bin/bash
if [ -z $1 ]
then
    echo 'Usage: $0 [number]'
    exit
fi

./tafel_$1.R | tee tafel_$1.log && open tafel_$1.pdf
#echo "./tafel_$1.R | tee tafel_$1.log && open tafel_$1.pdf"
