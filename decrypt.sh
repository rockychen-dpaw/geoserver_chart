#!/bin/bash
if [[ "$2" == "" ]]; then
    openssl des3 -d -in $1.des3 -out $1
else
    openssl des3 -d -in $1.des3 -out $2
fi
