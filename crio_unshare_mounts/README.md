# Overview

Thse machine config additions create a new mount namespace and causes both crio and kubelet to launch within it to hide their many many mounts from systemd.

It does so by creating:
 - A service called container-mount-namespace.service which spawns a separate namespace (via systemd's 'PrivateMounts' mechanism), and then sleeps forever.
 - An override file for each of crio.service and kubelet.service which wrap the original command under 'nsenter' so they both use the mount namespace created by 'container-mount-namespace.service'

With this in place, both kubelet and crio create their mounts in the new shared (with eachother) but private (from systemd) namespace.

## References:

mount_namespaces(7) unshare(1) nsenter(1) systemd.exec(5)

## Caveats:

The contents of the original commands are copied out of OpenShift 4.6; It would be good to automate a way to make this download the current version from the current cluster so it always matches the actual services.

# Usage

Frist, assemble all the overrides and such:

    make

Apply to all worker via:

    oc create -k worker

Apply to all masters via:

    oc create -k master
