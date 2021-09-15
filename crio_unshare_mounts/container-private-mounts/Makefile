GOPATH  ?= $(HOME)/go
MCMAKER := $(GOPATH)/bin/mcmaker


mc-container-mount-namespace.yaml: extractExecStart nsenterCmns container-mount-namespace.service 20-container-mount-namespace.conf
	$(MAKE) $(MCMAKER)
	$(MCMAKER) -name mc-container-mount-namespace -mcp master \
		file -source extractExecStart -path /usr/local/bin/extractExecStart -mode 0755 \
		file -source nsenterCmns -path /usr/local/bin/nsenterCmns -mode 0755 \
		unit -source container-mount-namespace.service \
		dropin -source 20-container-mount-namespace.conf -for kubelet.service \
		dropin -source 20-container-mount-namespace.conf -for crio.service


.PHONY: install
install: mc-container-mount-namespace.yaml
	oc apply -f $<


$(MCMAKER):
	go install github.com/lack/mcmaker@latest
