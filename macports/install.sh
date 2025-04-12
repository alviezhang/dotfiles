#!/bin/bash

cat ports.txt | grep -v -E "^[[:space:]]*(#|$)" | xargs sudo port install
