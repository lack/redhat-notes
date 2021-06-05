#!/bin/bash

cat <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $NAME
  namespace: openshift-machine-config-operator
spec:
  template:
    metadata:
      labels:
        name: $NAME
    spec:
      containers:
      - name: $NAME
        image: quay.io/centos/centos:8
        imagePullPolicy: IfNotPresent
        command:
        - "/sbin/chroot"
        - "/host"
        - "/bin/bash"
        - "-ec"
        args:
        - |
          echo "Current tang pin:"
          clevis-luks-list -d /dev/sda4 -s 1
          echo "Applying new tang pin: \$NEW_TANG_PIN"
          clevis-luks-edit -f -d /dev/sda4 -s 1 -c "\$NEW_TANG_PIN"
          echo "Pin applied successfully"
        env:
        - name: NEW_TANG_PIN
          value: >-
$(pr -to 12 <<<"$PIN")
        volumeMounts:
        - name: hostroot
          mountPath: /host
        securityContext:
          privileged: true
      volumes:
      - name: hostroot
        hostPath:
          path: /
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-node-critical
      restartPolicy: Never
      serviceAccount: machine-config-daemon
      serviceAccountName: machine-config-daemon
EOF