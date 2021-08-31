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
    # use all the cpus if kubelet is not configured yet
    cat /sys/fs/cgroup/cpuset/cpuset.cpus
  else
    jq -r '.defaultCpuSet' </var/lib/kubelet/cpu_manager_state
  fi
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

resetAffinity() {
  local cpuset="$1"
  local failcount=0
  local successcount=0
  logger "Recovery: Setting CPU affinity for critical processes \"$CRITICAL_PROCESSES\" to $cpuset"
  for proc in $CRITICAL_PROCESSES; do
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
    done
  done
  logger "Recovery: Re-affined $successcount pids successfully"
  if [[ $failcount -gt 0 ]]; then
    logger "Recovery: Failed to re-affine $failcount processes"
    return 1
  fi
}

setUnrestricted() {
  logger "Recovery: Setting critical system processes to have unrestricted CPU access"
  resetAffinity "$(unrestrictedCpuset)"
}

setRestricted() {
  logger "Recovery: Resetting critical system processes back to normally restricted access"
  resetAffinity "$(restrictedCpuset)"
}

currentAffinity() {
  local pid="$1"
  taskset -pc $pid | awk -F': ' '{print $2}'
}

waitForReady() {
  logger "Recovery: Waiting ${MAXIMUM_WAIT_TIME}s for the initialization to complete"
  local lastSystemdCpuset="$(currentAffinity 1)"
  local lastDesiredCpuset="$(unrestrictedCpuset)"
  local t=0 s=10
  while [[ $t -lt $MAXIMUM_WAIT_TIME ]]; do
    sleep $s
    ((t += s))
    # Re-check the current affinity of systemd, in case some other process has changed it
    local systemdCpuset="$(currentAffinity 1)"
    # Re-check the unrestricted Cpuset, as the allowed set of unreserved cores may change as pods are assigned to cores
    local desiredCpuset="$(unrestrictedCpuset)"
    if [[ $systemdCpuset != $lastSystemdCpuset || $lastDesiredCpuset != $desiredCpuset ]]; then
      resetAffinity "$desiredCpuset"
      lastSystemdCpuset="$(currentAffinity 1)"
      lastDesiredCpuset="$desiredCpuset"
    fi
  done
  logger "Recovery: Recovery Complete Timeout"
}

if ! unrestrictedCpuset >&/dev/null; then
  logger "Recovery: No unrestricted Cpuset could be detected"
  exit 1
fi

if ! restrictedCpuset >&/dev/null; then
  logger "Recovery: No restricted Cpuset has been configured.  We are already running unrestricted."
  exit 0
fi

# Ensure we reset the CPU affinity when we exit this script for any reason
# This way either after the timer expires or after the process is interrupted
# via ^C or SIGTERM, we return things back to the way they should be.
trap setRestricted EXIT

logger "Recovery: Recovery Mode Starting"
setUnrestricted
waitForReady
