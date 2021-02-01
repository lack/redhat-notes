# Overview

These [MCO](https://github.com/openshift/machine-config-operator) additions
create a new mount namespace and causes both CRI-O and Kubelet to launch within
it to hide their many many mounts from systemd.

It does so by creating:
 - A service called
   [container-mount-namespace.service](container-private-mounts/container-mount-namespace.service)
   which spawns a separate mount namespace and pins it in a well-known location
   `/run/container-mount-namespace/mnt`
 - An [override
   file](container-private-mounts/20-container-mount-namespace.conf) for each
   of `crio.service` and `kubelet.service` which wrap the startup commands so
   they both join the mount namespace created by
   `container-mount-namespace.service`
 - A convenience utility `/usr/local/bin/nsenterCms` for administrators or
   external utilities to easily enter this namespace

With this in place, both Kubelet and CRI-O create their mounts in the new
shared (with each other) but private (from systemd) namespace. And because this
namespace inherits from the main systemd mount namespace with slave
propagation, Kubelet and CRI-O (and associated containers) still have
visibility into any mounts created in the parent namespace by systemd and other
OS services.

The systemd drop-in can be easily reused with any executable systemd service if
there are other services which need to share the same mount namespace as CRI-O
and Kubelet.

# Usage

## OpenShift via MCO

Apply to all workers via:

    oc create -k worker

Apply to all masters via:

    oc create -k master

This has been lightly tested and has a [respectable pass rate](test_results) of
the OpenShift e2e tests.

## Generic Kubernetes

Provided for reference only, this hasn't been tested and may nuke your whole
cluster...

- Copy
  [container-mount-namespace.service](container-private-mounts/container-mount-namespace.service)
  into `/etc/systemd/system/`
- Copy [extractExecStart](container-private-mounts/extractExecStart) to
  `/usr/local/bin/` and make it executable
- Copy
  [20-container-mount-namespace.conf](container-private-mounts/20-container-mount-namespace.conf)
  into the systemd override directory for both Kubelet
  (`/etc/systemd/system/kubelet.service.d/`) and whatever container runtime you
  are using.
- Run `systemctl daemon-reload` and then restart both `kubelet.service` and the
  container runtime service.

# Implementation Notes

## Creating a mount namespace

The
[container-mount-namespace.service](container-private-mounts/container-mount-namespace.service)
uses the `unshare(1)` utility to create a new mount namespace with one-way
"slave" propagation from the top-level systemd mount namespace and bind-mount
it to a well-known location (`/run/container-mount-namespace/mnt`).

The `ExecStartPre` lines in the service set up the location as a bind-mount to
itself with `unbindable` mount propagation, since the kernel will not allow
pinning a mount namespace except in an unshared mountpoint.

## Overriding CRI-O and Kubelet to run in the namespace

It's deceptively tricky to set things up cleanly. All we need to do is wrap the
existing command in `nsenter --mount=/run/...`, but there's no straightforward
way to do this in systemd. You can clear and re-define `ExecStart`, but you
cannot prepend to it, append to it, or embed the current `ExecStart` inside
itself.

We need to preserve all of the prior command's syntax including some parts
(especialy in `kubelet.service`) that can't be hard-coded statically ahead of
time, since they are set to version-specific or machine-specific values at
installation time.

When installing by hand it's not too hard to write some logic that does a quick
read-modify-write to set the values from the current services, but this has 2
problems:
- Upgrades would need special handling in case these vaules change from version
  to version and our overrides would need to change to match.
- This can't be done in MCO without a double-reboot service-modifies-a-service
  scheme.

We need some clever logic that runs as part of systemd every boot. So how
clever can we get?

Systemd does allow environment files to be created in one phase (like
`ExecStartPre`) and reloaded and used in another phase (like `ExecStart`).
That's an idea! We can write a utility script like
[extractExecStart](container-private-mounts/extractExecStart) to pull the
original `ExecStart` value from the service we're wrapping, put in an
environment file, then pull it in and wrap it under `nsenter(1)` in our
overridden `ExecStart`. With one more caveat; if the original `ExecStart` needs
to dereference environment variables we need to re-wrap in bash because systemd
only does a single shot at variable expansion. 

The result is a self-bootstrapping systemd override like
[20-container-mount-namespace.conf](container-private-mounts/20-container-mount-namespace.conf)
which can be dropped-in to any executable systemd service without editing.

## Caveats

The mechanism used to wrap the services is pretty strict and does not play well
with others. Specifically if this is one of many overrides that touch
`ExecStart` of the service, it will ignore any except what's in the base
service file.

## References:

mount_namespaces(7) unshare(1) nsenter(1) systemd.exec(5)
