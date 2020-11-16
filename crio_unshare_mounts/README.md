# Overview

Thse machine config additions create a new mount namespace and causes both crio and kubelet to launch within it to hide their many many mounts from systemd.

It does so by creating:
 - A service called container-mount-namespace.service which spawns a separate namespace (via systemd's 'PrivateMounts' mechanism), and then sleeps forever.  We don't want to create the namespace in crio.service or kubelet.service, since if either one restarts they would lose eachother's namespaces.
 - An override file for each of crio.service and kubelet.service which wrap the original command under 'nsenter' so they both use the mount namespace created by 'container-mount-namespace.service'

With this in place, both kubelet and crio create their mounts in the new shared (with eachother) but private (from systemd) namespace.

## References:

mount_namespaces(7) unshare(1) nsenter(1) systemd.exec(5)

# Usage

Frist, fetch the current service ExecStart lines and assemble all the overrides:

    make HOST=nodename

Apply to all worker via:

    oc create -k worker

Apply to all masters via:

    oc create -k master

## Caveats:

Some work is still needed to productize this in a more robust way, if it turns out it actually solves the problem it is intended to solve.

Potential ideas for productization:
 - Alter systemd so that 'JoinNamespaceOf' covers mount namespaces in addition to what it already does
 - Alter systemd so that slices can have unique namespaces
 - Alter both crio and hypecube/kubelet to have an optional commandline argument to join a pre-existing mount namespace (basically wrap the work that 'nsenter' is doing in this example into each of those commands) so we don't have to patch ExecStart any more

