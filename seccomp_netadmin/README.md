Contents
========

original-seccomp.json: The default seccomp profile from cri-o (and docker, etc)

inverted-seccomp.json: An attempt at inverting the logic of original-seccomp.json to be a "deny-by-default"

example-seccomp.json: The inverted seccomp plus extra rules to limit SO_PRIORITY SO_DEBUG SO_SNDBUFFORCE and SO_RCVBUFFORCE that would normally be allowed by CAP_NET_ADMIN
