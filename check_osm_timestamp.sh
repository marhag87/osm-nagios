#!/bin/bash

source /usr/lib64/nagios/plugins/utils.sh

for dir in ~osm/.osmosis/*; do
  [[ -e $dir ]] || continue
  diff <(curl -s "$(awk -F '=' '/baseUrl/ {print $2}' ${dir}/configuration.txt)/state.txt" | grep timestamp) <(grep timestamp ${dir}/state.txt) > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo "${dir##*/} differs"
    exit $STATE_CRITICAL
  fi
done

echo "all timestamps match"
exit $STATE_OK
