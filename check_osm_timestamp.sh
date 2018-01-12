#!/bin/bash

set -o pipefail

source /usr/lib64/nagios/plugins/utils.sh

PROGNAME=$(basename "$0")

function print_usage {
  echo "Usage: $PROGNAME -w <number> -c <number>"
  echo "Usage: $PROGNAME --help"
  echo "     Additional parameters:"
  echo "         -w Number of days difference needed to trigger a warning, defaults to 3"
  echo "         -c Number of days difference needed to trigger a critical, defaults to 5"
}

warning=3
critical=5

while test -n "$1"; do
    case "$1" in
        --help)
            print_usage
            exit "$STATE_OK"
            ;;
        -h)
            print_usage
            exit "$STATE_OK"
            ;;
        -w)
            warning=$2
            shift
            ;;
	-c)
            critical=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit "$STATE_UNKNOWN"
            ;;
    esac
    shift
done


for dir in ~osm/.osmosis/*; do
  [[ -e $dir ]] || continue
  upstream_timestamp=$(date -d $(curl -s "$(awk -F '=' '/baseUrl/ {print $2}' ${dir}/configuration.txt)/state.txt" | awk -F '=' '/timestamp/ {print $2}' | tr -d '\\') +%s 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "Could not fetch upstream timestamp"
    exit $STATE_UNKNOWN
  fi
  state_timestamp=$(date -d $(awk -F '=' '/timestamp/ {print $2}' ${dir}/state.txt | tr -d '\\') +%s)
  days_difference=$(($(($upstream_timestamp - $state_timestamp)) / 86400))
  if [[ $days_difference -ge $critical ]]; then
    echo "State for ${dir##*/} differs by $days_difference day(s)"
    exit $STATE_CRITICAL
  fi
  if [[ $days_difference -ge $warning ]]; then
    echo "State for ${dir##*/} differs by $days_difference day(s)"
    exit $STATE_WARNING
  fi
done

echo "All timestamps are within range"
exit $STATE_OK
