#!/bin/sh
##
# Script to remove/undepoy all project resources from GKE & GCE.
##

# Delete mongod stateful set + mongodb service + secrets + host vm configuer daemonset
kubectl delete statefulsets mongod
kubectl delete services mongodb-service
kubectl delete secret shared-bootstrap-data
kubectl delete daemonset hostvm-configurer
sleep 3

# Delete persistent volume claims
kubectl delete persistentvolumeclaims -l role=mongo
sleep 3

# Delete persistent volumes
kubectl delete persistentvolumes data-volume-1
kubectl delete persistentvolumes data-volume-2
kubectl delete persistentvolumes data-volume-3
sleep 20

# Delete GCE disks and then delete whole Kubernetes cluster (including its VM instances)
gcloud -q compute disks delete pd-ssd-disk-1
gcloud -q compute disks delete pd-ssd-disk-2
gcloud -q compute disks delete pd-ssd-disk-3
gcloud -q container clusters delete "gke-mongodb-demo-cluster"

