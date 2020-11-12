# Overview

This machine config addition moves crio down into its own mount namespace to hide its many overlay mounts from systemd.

It does so by creating a service override file in `/etc/systemd/system/crio.service.d/override.conf` which turns on systemd's PrivateMounts mode, which hides crio's container-specific overlay mounts from systemd. This is roughly equivalent to running crio under `unshare -m --propagation=slave`, but doesn't involve editing the ExecStart parameter.

With this in place:
- crio sees the mounts done by kubelet in the top-level mount namespace (so it sees the secret mounts etc)
- crio creates its container overlay mounts in its own namespace but these are not propagated up to the parent namespace (so systemd will never see them)

End result: this isn't 100% isolation of OpenShift mounts from systemd, as the kubelet mounts are still in the top-level namespace, but it's reduced the number of systemd-facing mounts.

## References:

mount_namespaces(7) unshare(1) systemd.exec(5)

# Usage

Apply to all workers via:

    oc create -k worker

Apply to all masters via:

    oc create -k master
