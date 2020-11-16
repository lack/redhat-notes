tail -f /var/log/cloud-init-output.log 
oc get nodes
ssh core@cnfdc4
ssh core@cnfdc4 sudo cat /proc/1/mounts > pid1.mounts
ssh core@cnfdc4 sudo pidof /usr/bin/crio
ssh core@cnfdc4 sudo cat /proc/4448/mounts >crio.mounts
ssh core@cnfdc4 sudo pidof /usr/bin/crio
ssh core@cnfdc4 sudo cat /proc/4899/mounts >crio.mounts
ls
diff -u pid1.mounts crio.mounts 
wc -l pid1.mounts 
wc -l pid1.mounts crio.mounts 
ls
mv redhat-notes/crio_unshare_mounts/*.out .
tmux attach -d
