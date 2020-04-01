#!/bin/bash


for target in "$@"
do
    make -C $target uninstall
done
