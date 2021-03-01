# Process Interrogator for OpenShift

The [process-exporter](https://github.com/ncabatoff/process-exporter) utility
adds per-process statistics to prometheus, but doesn't afford an easy way to
differentiate pod processes from non-pod processes, which we would like.

The first attempt at finding a way around this involves adding the ability to
filter processes in process-exporter by parent PID (work done
[here](https://github.com/lack/process-exporter/tree/parent-matching)), and
then setting up a config file to group all processes which have a PPID == 1,
meaning all top-level processes on the machine get grouped (and all lower-level
children get grouped in with their parents). With this in place, we know that
all pods will be in the groupname "conmon", and everything else are non-pod
processes.

The objects in process-exporter wrap a custom build of the PPID-filtwering
process-exporter with proper prometheus config to bring it all together.

## Example Prometheus Filters

General notes:

- We use `sum without(mode)` because process-exporter splits user CPU time and
  system CPU time into 2 separate counters, and this adds them into a single
  counter per process.

- We use `rate` because CPU is calculated in CPU seconds (an increasing
  counter).  The nice thing is that calculating the rate of "CPU seconds per
  second" ends up with the same metric as the main OpenShift monitoring like
  `pod:container_cpu_usage:sum`.  A value of "1" means we used 1s of CPU for
  every second we ran, or 100% of one core.

High-level CPU usage for all non-pod processes:

    sum without(mode) (rate(namedprocess_namegroup_cpu_seconds_total{groupname!~"conmon.*"}[1m]))

The same, but splitting out all threads and sub-processes:

    sum without(mode) (rate(namedprocess_namegroup_thread_cpu_seconds_total{groupname!~"conmon.*"}[1m]))

All threads and sub-processes including pods:

    sum without(mode) (rate(namedprocess_namegroup_thread_cpu_seconds_total[1m]))

## TODO
- Cleaner packaging
- Maybe adapt process-exporter to do more container-gnostic filtering, perhaps
  based on cgroup filtering?
