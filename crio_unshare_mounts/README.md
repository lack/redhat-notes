This machine config addition moves crio down into its own mount namespace to hide its many overlay mounts from systemd.

It does so by creating an override file in /etc/systemd/system/crio.service.d/override.conf which wraps the ExecStart inside of `unshare -m --propagation slave` to hide crio's container-specific overlay mounts from systemd.

With this in place:
- crio sees the mounts done by kubelet in the top-level mount namespace (so it sees the secret mounts etc)
- crio creates its container overlay mounts in its own namespace but these are not propagated up to the parent namespace (so systemd will never see them)

End result: this isn't 100% isolation of k8s mounts from systemd, as the kubelet mounts are still in the top-level namespace, but it's reduced the number of systemd-facing mounts.
