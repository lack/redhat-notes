GOPATH  ?= $(HOME)/go
MCMAKER := $(GOPATH)/bin/mcmaker


04-accelerated-container-startup.yaml: accelerated-container-shutdown.service accelerated-container-startup.service accelerated-container-startup.sh
	$(MAKE) $(MCMAKER)
	$(MCMAKER) -name 04-accelerated-container-startup \
		file -source accelerated-container-startup.sh -path /usr/local/bin/accelerated-container-startup.sh -mode 0755 \
		unit -source accelerated-container-startup.service \
		unit -source accelerated-container-shutdown.service


.PHONY: test
test: test.sh accelerated-container-startup.sh
	./test.sh


.PHONY: install
install: 04-accelerated-container-startup.yaml
	oc apply -f $<


$(MCMAKER): 
	go install github.com/lack/mcmaker@latest
