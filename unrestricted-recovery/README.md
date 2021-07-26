This generates a MachineConfig file that alters the CPU pinning on a machine
with workload partitioning enabled. It moves a set of critical system processes
off of the restricted CPUs and to the full complement of available CPUs during
startup and shutdown.

Run 'make' to generate a yaml file that can be applied to an ocp system.
