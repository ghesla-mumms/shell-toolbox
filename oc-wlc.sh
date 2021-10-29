#!/bin/bash

oc status | egrep "In project .* on server.*"

echo "The following workloads are sub-optimal:"
for type in deployment deploymentConfig; do
  echo "== ${type}s =="
  oc get ${type} --all-namespaces -o=jsonpath='{range $.items[?(@.status.unavailableReplicas!=0)]}{.metadata.namespace}{" '${type}'/"}{.metadata.name}{"\n"}'
done

echo "== statefulSets =="
oc get statefulSet --all-namespaces -o=jsonpath='{range $.items[?(@.status.replicas!=@.status.readyReplicas)]}{.metadata.namespace}{" statefulSet/"}{.metadata.name}{"\n"}'

echo "== daemonSets =="
oc get daemonSet --all-namespaces -o=jsonpath='{range $.items[?(@.status.numberMisscheduled!=0)]}{.metadata.namespace}{" daemonSet/"}{.metadata.name}{"\n"}'

echo "== pods =="
oc get po --all-namespaces --field-selector 'status.phase=Running' -o=jsonpath='{range $.items[?(@.status.containerStatuses[].ready!=true)]}{.metadata.namespace}{" pod/"}{.metadata.name}{"\n"}'

echo "Also checking openshift-logging..."
oc get elasticsearch -A

echo "If any of these are not green investigate:"
for kibana_pod_name in $(oc get -n openshift-logging po --selector='component=kibana' -o jsonpath='{.items[*].metadata.name}');   do
  echo ${kibana_pod_name};
  oc -n openshift-logging rsh -c kibana ${kibana_pod_name} curl -s http://127.0.0.1:5601/api/status | jq .status.overall.state;
done
