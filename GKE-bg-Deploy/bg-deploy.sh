#!/bin/bash

# bg-deploy.sh <servicename> <version> <green-deployment.yaml>
# Deployment name should be <service>-<version>

DEPLOYMENTNAME=$1-$2
SERVICE=$1
VERSION=$2
DEPLOYMENTFILE=$3
SERVICEFILE=$4
SERVICEINTERNALFILE=$5

echo "test1"
CURRENT_DEPLOYMENT=$(kubectl get deployments |grep "^$SERVICE" | awk '{print $1}')

echo "test2"
envsubst < $DEPLOYMENTFILE | kubectl apply -f - 
echo "test3"
echo "$DEPLOYMENTNAME Deployed "
# Wait until the Deployment is ready by checking the MinimumReplicasAvailable condition.
READY=$(kubectl get deployment $DEPLOYMENTNAME -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
while [[ "$READY" != "True" ]]; do
    READY=$(kubectl get deployment $DEPLOYMENTNAME -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
    sleep 5
done

envsubst < $SERVICEFILE | kubectl apply -f - 
envsubst < $SERVICEINTERNALFILE | kubectl apply -f - 

echo "Service Updated."

if [ ! -z "$CURRENT_DEPLOYMENT" ]; then
    echo "delete $CURRENT_DEPLOYMENT"
    kubectl delete deployment $CURRENT_DEPLOYMENT
fi
