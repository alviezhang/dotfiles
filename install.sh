#!/bin/bash


for target in "$@"
do
    make -C $target install
done
