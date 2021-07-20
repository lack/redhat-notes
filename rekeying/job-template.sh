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
        image: registry.access.redhat.com/ubi8/ubi-minimal:8.4
        imagePullPolicy: IfNotPresent
        command:
        - "/sbin/chroot"
        - "/host"
        - "/bin/bash"
        - "-ec"
        args:
        - |
          echo "Current tang pin:"
          clevis-luks-list -d \$ROOT_DEV -s 1
          echo "Applying new tang pin: \$NEW_TANG_PIN"
          clevis-luks-edit -f -d \$ROOT_DEV -s 1 -c "\$NEW_TANG_PIN"
          echo "Pin applied successfully"
        env:
        - name: ROOT_DEV
          value: /dev/sda4
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
