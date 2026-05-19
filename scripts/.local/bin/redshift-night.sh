#!/bin/bash

HOUR=$(date +%H)

if [ "$HOUR" -ge 18 ] || [ "$HOUR" -lt 6 ]; then
    redshift -O 3000
fi
