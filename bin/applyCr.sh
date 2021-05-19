#!/bin/bash

shopt -s nullglob

SOURCE=$1
PENDING=./pending
APPLIED=./applied

success=0
iterations=0
sleep_time=10
max_iterations=72
applied=0
objcount=0

rm -rf $PENDING $APPLIED
mkdir -p $PENDING $APPLIED
for f in $SOURCE/*.yaml; do
	cp $f $PENDING/
	((objcount++))
done
echo -n "Starting at "; date -u
until [[ $success -eq 1 ]] || [[ $((iterations++)) -eq $max_iterations ]]; do
	failed=0
	tried=0
	echo "------------------------------------------------"
	for f in $PENDING/*.yaml; do
		((tried++))
		oc apply -f $f
		if [[ $? -ne 0 ]]; then
			((failed++))
		else
			((applied++))
			mv $f $APPLIED/
		fi
	done
	echo "------------------------------------------------"
	echo "Applied $applied/$objcount so far ($failed/$tried failed this time)"
	if [[ $failed -gt 0 ]]; then
		success=0
		sleep $sleep_time
	else
		success=1
	fi
done
echo -n "Completed at "; date -u
