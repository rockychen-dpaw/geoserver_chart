#!/bin/bash
openssl des3 -d -in $1.des3 -out $1
