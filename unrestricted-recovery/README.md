This generates a MachineConfig file that alters the CPU pinning on a machine
with workload partitioning enabled. It moves a set of critical system processes
off of the restricted CPUs and to the full complement of available CPUs during
startup and shutdown.

Run `make install` to install the current MachineConfig to your cluster
(assumes `oc` is set up and functioning with proper authorization to create
MachineConfig objects)

If you make changes to the source service files or shell script, run `make` to
re-generate a yaml file that can be applied to an ocp system.
This requires some go utilities to be downloaded and installed.

