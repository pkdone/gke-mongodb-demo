#!/bin/sh
##
# Script to deploy a Kubernetes project with a StatefulSet running a MongoDB Replica Set, to GKE.
##

# Create new GKE Kubernetes cluster (using host node VM images based on Debian
# rather than ChromiumOS default & also use slightly larger VMs than default)
gcloud container clusters create "gke-mongodb-demo-cluster" --image-type=CONTAINER_VM --machine-type=n1-standard-2

# Configure host VM using daemonset to add XFS mounting support and disable hugepages
kubectl apply -f ../resources/hostvm-node-configurer-daemonset.yaml

# Register GCE Fast SSD persistent disks and then create the persistent disks 
echo "Creating GCE disks"
kubectl apply -f ../resources/gce-ssd-storageclass.yaml
sleep 5
for i in 1 2 3
do
    gcloud compute disks create --size 10GB --type pd-ssd pd-ssd-disk-$i
done
sleep 3

# Create persistent volumes using disks created above
echo "Creating GKE Persistent Volumes"
for i in 1 2 3
do
    sed -e "s/INST/${i}/g" ../resources/xfs-gce-ssd-persistentvolume.yaml > /tmp/xfs-gce-ssd-persistentvolume.yaml
    kubectl apply -f /tmp/xfs-gce-ssd-persistentvolume.yaml
done
rm /tmp/xfs-gce-ssd-persistentvolume.yaml
sleep 3

# Create keyfile for the MongoD cluster as a Kubernetes shared secret
TMPFILE=$(mktemp)
/usr/bin/openssl rand -base64 741 > $TMPFILE
kubectl create secret generic shared-bootstrap-data --from-file=internal-auth-mongodb-keyfile=$TMPFILE
rm $TMPFILE

# Create mongodb service with mongod stateful-set
kubectl apply -f ../resources/mongodb-service.yaml
sleep 5

# Print current deployment state (unlikely to be finished yet)
kubectl get all 
kubectl get persistentvolumes
echo
echo "Keep running the following command until all 'mongod-n' pods are shown as running:  kubectl get all"
echo

