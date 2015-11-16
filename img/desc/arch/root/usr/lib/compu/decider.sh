#!/bin/bash


if [ -z "$JOBID" ]; then
  echo job id not passed..
  exit 1
fi

ocmd="$@"

u=$(stat -c %U /sys/fs/cgroup/cpuset/compu/j${JOBID}/tasks 2> /dev/null)

# echo $ju

if [ "$u" = "$(id -nu)" ]; then
  if [ -n "$ocmd" ]; then
    exec cgexec -g cpuset:compu/j$JOBID $ocmd
  else
    exec cgexec -g cpuset:compu/j$JOBID $SHELL
  fi
else
  echo user "$(id -nu)" has not reserved JOBID=$JOBID
fi
