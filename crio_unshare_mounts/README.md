# Overview

Thse machine config additions create a new mount namespace and causes both crio and kubelet to launch within it to hide their many many mounts from systemd.

It does so by creating:
 - A service called container-mount-namespace.service which spawns a separate 'slave' mount namespace (via unshare) and pins it in a well-known location `/run/container-mount-namespace/mnt`
 - An override file for each of crio.service and kubelet.service which wrap the original command under 'nsenter' so they both join the mount namespace created by 'container-mount-namespace.service'
 - A convenience utility `/usr/local/bin/nsenterCms` for administrators or external utilities to easily enter this namespace

With this in place, both kubelet and crio create their mounts in the new shared (with eachother) but private (from systemd) namespace.

## References:

mount_namespaces(7) unshare(1) nsenter(1) systemd.exec(5)

# Usage

Unlike previous releases of this proof-of-concept, now no customization is needed any more, unless we want to wrap more services than just crio.service and kubelet.service!

Apply to all worker via:

    oc create -k worker

Apply to all masters via:

    oc create -k master

## Caveats

The mechanism used to wrap the services is pretty strict: specifically if this is one of many overrides that touch ExecStart of the service, it will ignore any except what's in the base service file.
