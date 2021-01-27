all: mc-container-mount-namespace.yaml

clean:
	rm -f mc-crio-ns-override.yaml-fragment mc-kubelet-ns-override.yaml-fragment mc-container-mount-ns-service.yaml-fragment crio-override.conf kubelet-override.conf crio.execstart kubelet.execstart crio.service kubelet.service

BASE64=/usr/bin/base64
ENVSUB=/usr/bin/envsubst

%.execstart: %.service
	sed -n -f extractExecStart.sed $< >$@

%-override.conf: %.execstart nsenter-template-override.conf
	ORIGCOMMAND=$$(<$<) \
		$(ENVSUB) '$$ORIGCOMMAND' <nsenter-template-override.conf >$@

mc-%-ns-override.yaml-fragment: %-override.conf mc-add-file-template.yaml crio-override.conf
	PATH=/etc/systemd/system/$*.service.d/override.conf \
		CONTENTS=$$($(BASE64) -w0 $<) \
		$(ENVSUB) '$$PATH $$CONTENTS' <mc-add-file-template.yaml >$@


kubelet.service:
	@[ $(HOST) ] || (echo "You need to set HOST= on your make commandline (ie: make HOST=cnfdc4)"; exit 1)
	scp core@$(HOST):/etc/systemd/system/kubelet.service $@

crio.service:
	@[ $(HOST) ] || (echo "You need to set HOST= on your make commandline (ie: make HOST=cnfdc4)"; exit 1)
	scp core@$(HOST):/usr/lib/systemd/system/crio.service $@

mc-container-mount-ns-service.yaml-fragment: mc-add-file-template.yaml container-mount-namespace.service
	PATH=/etc/systemd/system/container-mount-namespace.service \
		CONTENTS=$$($(BASE64) -w0 ./container-mount-namespace.service) \
		$(ENVSUB) '$$PATH $$CONTENTS' <$< >$@

mc-container-mount-namespace.yaml: mc-container-mount-namespace-template.yaml mc-container-mount-ns-service.yaml-fragment mc-crio-ns-override.yaml-fragment mc-kubelet-ns-override.yaml-fragment
	cat $^ > $@
