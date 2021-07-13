#!/bin/bash
#
# Temporarily reset the core system processes's CPU affinity to be unrestricted to accellerate startup and shutdown
#
# The defaults below can be overridden via environment variables
#

# The default set of critical processes whose affinity should be temporarily unbound:
CRITICAL_PROCESSES=${CRITICAL_PROCESSES:-"systemd ovs crio kubelet NetworkManager conmon dbus"}

# Default wait time is 600s = 10m:
MAXIMUM_WAIT_TIME=${MAXIMUM_WAIT_TIME:-600}

unrestrictedCpuset() {
  if [[ ! -e /var/lib/kubelet/cpu_manager_state ]]; then
    return 1
  fi
  jq -r '.defaultCpuSet' </var/lib/kubelet/cpu_manager_state
}

restrictedCpuset() {
  for arg in $(</proc/cmdline); do
    if [[ $arg =~ ^systemd.cpu_affinity= ]]; then
      echo ${arg#*=}
      return 0
    fi
  done
  return 1
}

logAffinity() {
  echo "----------------------------------------------------------"
  for proc in $CRITICAL_PROCESSES; do
    echo "- $proc"
    local pids="$(pgrep $proc)"
    for pid in $pids; do
      taskset -p $pid | sed -e 's/^/  - /'
    done
  done
}

resetAffinity() {
  local cpuset="$1"
  local failcount=0
  local successcount=0
  echo "=========================================================="
  echo "Setting CPU affinity for critical processes \"$CRITICAL_PROCESSES\" to $cpuset"
  for proc in $CRITICAL_PROCESSES; do
    echo "- $proc"
    local pids="$(pgrep $proc)"
    for pid in $pids; do
      local tasksetOutput
      tasksetOutput="$(taskset -apc "$cpuset" $pid 2>&1)"
      if [[ $? -ne 0 ]]; then
        echo "ERROR: $tasksetOutput"
        ((failcount++))
      else
        ((successcount++))
      fi
      taskset -p $pid | sed -e 's/^/  - /'
    done
  done
  echo "Re-affined $successcount pids successfully"
  if [[ $failcount -gt 0 ]]; then
    echo "Failed to re-affine $failcount processes"
    return 1
  fi
}

setUnrestricted() {
  logger "Setting critical system processes to have unrestricted CPU access"
  resetAffinity "$(unrestrictedCpuset)"
}

setRestricted() {
  logger "Resetting critical system processes back to normally restricted access"
  resetAffinity "$(restrictedCpuset)"
}

waitForReady() {
  echo "=========================================================="
  echo "Waiting ${MAXIMUM_WAIT_TIME}s for the initialization to complete"
  local t=0 s=10
  while [[ $t -lt $MAXIMUM_WAIT_TIME ]]; do
    # TODO: Can we query the state somehow and interrupt this sooner?
    # Does 'crio' know when we're "done"?  Maybe via 'crictl ps | grep Pending | wc -l'?
    local pending=$(crictl ps | grep Pending | wc -l)
    echo "DEBUG: Crio lists $pending containers as Pending"
    sleep $s
    ((t += s))
    # Because 'tuned' may mess with us, and the allowed set of unreserved cores
    # may change as pods come up, we reassert the unrestricted affinity every
    # 10s
    resetAffinity "$(unrestrictedCpuset)"
  done
}

if ! unrestrictedCpuset >&/dev/null; then
  echo "No unrestricted Cpuset could be detected.  Perhaps kubelet is not running yet?"
  exit 1
fi

if ! restrictedCpuset >&/dev/null; then
  echo "No restricted Cpuset has been configured.  We are already running unrestricted."
  exit 0
fi

# Ensure we reset the CPU affinity when we exit this script for any reason
# This way either after the timer expires or after the process is interrupted
# via ^C or SIGTERM, we return things back to the way they should be.
trap setRestricted EXIT

setUnrestricted
waitForReady
