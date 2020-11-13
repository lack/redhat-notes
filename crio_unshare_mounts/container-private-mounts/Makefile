all: mc-crio-ns-override.yaml mc-kubelet-ns-override.yaml mc-container-mount-ns-service.yaml

clean: mc-crio-ns-override.yaml mc-kubelet-ns-override.yaml mc-container-mount-ns-service.yaml crio-override.conf kubelet-override.conf
	rm -f $^

BASE64=/usr/bin/base64
ENVSUB=/usr/bin/envsubst

crio-override.conf: nsenter-template-override.conf crio-origcommand
	ORIGCOMMAND=$$(<crio-origcommand) \
		$(ENVSUB) '$$ORIGCOMMAND' <$< >$@

mc-crio-ns-override.yaml: mc-add-file-template.yaml crio-override.conf
	OBJNAME=crio-ns-override \
		PATH=/etc/systemd/system/crio.service.d/override.conf \
		CONTENTS=$$($(BASE64) -w0 crio-override.conf) \
		$(ENVSUB) '$$OBJNAME $$PATH $$CONTENTS' <$< >$@

kubelet-override.conf: nsenter-template-override.conf kubelet-origcommand
	ORIGCOMMAND=$$(<kubelet-origcommand) \
		$(ENVSUB) '$$ORIGCOMMAND' <$< >$@

mc-kubelet-ns-override.yaml: mc-add-file-template.yaml kubelet-override.conf
	OBJNAME=kubelet-ns-override \
		PATH=/etc/systemd/system/kubelet.service.d/override.conf \
		CONTENTS=$$($(BASE64) -w0 kubelet-override.conf) \
		$(ENVSUB) '$$OBJNAME $$PATH $$CONTENTS' <$< >$@

mc-container-mount-ns-service.yaml: mc-add-file-template.yaml container-mount-namespace.service
	OBJNAME=container-mount-ns-service \
		PATH=/etc/systemd/system/container-mount-namespace.service \
		CONTENTS=$$($(BASE64) -w0 ./container-mount-namespace.service) \
		$(ENVSUB) '$$OBJNAME $$PATH $$CONTENTS' <$< >$@

