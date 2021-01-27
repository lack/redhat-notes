all: mc-container-mount-namespace.yaml

clean:
	rm -f mc-*-fragment.yaml

BASE64=/usr/bin/base64
ENVSUB=/usr/bin/envsubst

mc-%-ns-override-fragment.yaml: 20-container-mount-namespace.conf mc-add-file-template.yaml
	PATH=/etc/systemd/system/$*.service.d/20-container-mount-namespace.conf MODE=420 \
		CONTENTS=$$($(BASE64) -w0 $<) \
		$(ENVSUB) '$$PATH $$MODE $$CONTENTS' <mc-add-file-template.yaml >$@

mc-container-mount-ns-service-fragment.yaml: container-mount-namespace.service mc-add-file-template.yaml
	PATH=/etc/systemd/system/container-mount-namespace.service MODE=420 \
		CONTENTS=$$($(BASE64) -w0 $<) \
		$(ENVSUB) '$$PATH $$MODE $$CONTENTS' <mc-add-file-template.yaml >$@

mc-%-tool-fragment.yaml: % mc-add-file-template.yaml
	PATH=/usr/local/bin/$* MODE=493 \
		CONTENTS=$$($(BASE64) -w0 $<) \
		$(ENVSUB) '$$PATH $$MODE $$CONTENTS' <mc-add-file-template.yaml >$@

mc-container-mount-namespace.yaml: mc-container-mount-namespace-template.yaml mc-container-mount-ns-service-fragment.yaml mc-crio-ns-override-fragment.yaml mc-kubelet-ns-override-fragment.yaml mc-extractExecStart-tool-fragment.yaml mc-nsenterCms-tool-fragment.yaml
	cat $^ > $@
