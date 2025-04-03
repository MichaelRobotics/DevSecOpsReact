#!/bin/bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-username="$DOCKERHUB_USERNAME" \
  --docker-password="$DOCKERHUB_TOKEN" \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -