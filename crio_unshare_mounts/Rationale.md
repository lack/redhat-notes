# Quick Overview: What are we proposing to change?

![Fig 1: Current mount propagation](images/Original%20k8s%20mount%20propagation.png)

_Fig 1: Current mount propagation_

Today, Kubelet and the Container Runtime all run in the same mount namespace as
the host OS (systemd, login shells, system daemons)

In fact, the documentation for the `mountPropagation` volumeMount parameter, as
well as the "Mount Propagation" e2e test in kubernetes/kubernetes both enforce
a set of 3 guarantees about mountpoint visibility:

1. Mounts originating in the host OS are visible to the Container Runtime, OCI
   hooks, Kubelet, and container volumeMounts with `MountPropagation:
   HostToContainer` (or `Bidirectional`)
2. Mounts originating in the Container Runtime, OCI hooks, Kubelet, and
   container volumeMounts with `mountPropagation: Bidirectional` are visible to
   each other and container volumeMounts with `MountPropagation:
   HostToContainer`
3. Mounts originating in the Container Runtime, OCI hooks, Kubelet, and
   container volumeMounts with `mountPropagation: Bidirectional` are visible to
   the host OS

Of those 3 guarantees mentioned above, the first 2 are critical to the
Kubernetes and container-native operations, and would not change, but the 3rd
guarantee would be demoted to an optional configuration choice.

![Fig 2: Proposed support for hidden mount propagation](images/Proposed%20hidden%20k8s%20mount%20propagation.png)

_Fig 2: Proposed support for hidden mount propagation_

# Why make a change?

## Systemd Efficiency

Today systemd is adversely affected by a large number of mount points. This
appears to be rooted in the lack of granularity in the events the kernel sends
to systemd about mountpoint changes, which necessitates a full rescan of all
mountpoints even on a minor change or single mountpoint addition.  (See
[BZ1819869](https://bugzilla.redhat.com/show_bug.cgi?id=1819868) for more
details)

Even a fairly small OpenShift deployment today has upwards of 400 mountpoints
on every node owned by Kubelet, the Container Runtime, and infrastructure
containers like OVN or CSI operators. Hiding the container mount points reduces
the steady-state systemd CPU utilization from ~10% to ~0% on every worker node,
and the improvement would be greater on more heavily-loaded systems with more
container-specific mountpoints.

## Tidiness and Encapsulation

These container overlay mounts, secret and configmap mounts, and namespace
mounts are all internal implementation details around the way the Kubernetes
and the Container Runtime allocate resources to containers. For normal
day-to-day operation, there is no need for these special-use mounts to be
visible in the host OS's top-level 'mount' or 'findmnt' output.

## Security

While access to container-specific mounts in Kubernetes (like secrets) today
are protected by filesystem permissions, the fact that the locations are
visible to unprivileged users via the 'mount' command can provide information
which could be used in conjunction with other vulnerabilities to decipher
secrets or other protected container mount contents. Locking access to even
listing the mountpoints behind the ability to enter the mount namespace (which
in turn requires `CAP_SYS_CHROOT` and `CAP_SYS_ADMIN`) removes one level of
potential access to container-specific mounts.

# What exactly would change

## From the end-user's perspective

The original "everything-in-one-namespace" mode of operation would still be
allowed, but users or distributions would be allowed (or maybe even
encouraged?) to set up their init systems so that the Container Runtime and
Kubelet are in a separate mount namespace separate from the host OS, provided
this uses 'slave/shared' propagation so that host OS-mounted filesystems are
still available to the Container Runtime, Kubelet, and the containers they
spawn, and any changes in the 2nd-level namespace is propagated down to
lower-level namespaces.

For example, a user on a Linux system with systemd could use a systemd service
like
[container-mount-namespace.service](container-private-mounts/container-mount-namespace.service)
to create the mount namespace, then a drop-in like
[20-container-mount-namespace.conf](container-private-mounts/20-container-mount-namespace.conf)
for both kubelet.service and the appropriate container runtime service so they
enter that namespace before execution.  (See the
[extractExecStart](container-private-mounts/extractExecStart) helper script
for details on how the drop-in functions.)

An administrator wanting to examine the container mounts can easily run
`nsenter` to spawn a shell or other command inside the container mount
namespace, and likewise any 3rd-party service that needs access to these mounts
could use `nsenter` or a drop-in like the example above to do the same.

## From the Kubernetes perspective

The "Mount Propagation" e2e test needs alteration, to detect when a separate
container mount namespace is present and if so, enforce the slightly different
propagation rules.  The documentation for the `mountPropagation` property needs
a similar change.  An initial attempt at this implementation is [in this
branch](https://github.com/lack/kubernetes/tree/hide_container_mountpoints-k8s).

The installation guide for Kubernetes would also need a small addition, to
outline and demonstrate this optional environmental change.

# References

- [Proof-of-concept for
  OpenShift](https://github.com/lack/redhat-notes/tree/main/crio_unshare_mounts)
  using MachineConfigOperator to deploy the systemd service and drop-ins
- [BZ1819869](https://bugzilla.redhat.com/show_bug.cgi?id=1819868) goes into a
  deeper discussion about the systemd CPU usage issue
