#!/bin/sh
# Entrypoint of the Docker image: sets up the cgroups that BenchExec needs for
# run.py, as described in BenchExec's doc/benchexec-in-container.md. This
# requires starting the container with `docker run --privileged --cap-drop=all`;
# without it, run.py only works with --sequential.
set -eu

if mkdir -p /sys/fs/cgroup/init /sys/fs/cgroup/benchexec 2>/dev/null; then
  # Move the init process to its own cgroup, so that controllers can be enabled
  echo $$ > /sys/fs/cgroup/init/cgroup.procs
  for controller in $(cat /sys/fs/cgroup/cgroup.controllers); do
    echo "+$controller" > /sys/fs/cgroup/cgroup.subtree_control
    echo "+$controller" > /sys/fs/cgroup/benchexec/cgroup.subtree_control
  done
else
  echo "note: cgroups are not writable, so run.py only works with --sequential;" \
       "start the container with --privileged --cap-drop=all for pinned runs" >&2
fi

exec "$@"
