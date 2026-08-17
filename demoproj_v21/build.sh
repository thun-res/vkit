#!/usr/bin/env bash
i=0
while [ $i -lt 20 ]; do
    printf 'PROGRESS_%d\r' $i
    sleep 0.3
    i=$((i+1))
done
printf 'ALLFRAMESDONE\n'
exit 0
