#$!/bin/bash
#set -x
FORMAT=yaml
BASEDIR=archive_artifacts/gca-prod-cluster-backup

UNSUPPORTED_TYPES=(
bindings
clusterrolebindings.authorization.openshift.io
clusterrolebindings.rbac.authorization.k8s.io
clusterroles.authorization.openshift.io
clusterroles.rbac.authorization.k8s.io
componentstatuses
imagesignatures.image.openshift.io
imagestreamimports.image.openshift.io
imagestreammappings.image.openshift.io
imagestreamtags.image.openshift.io
imagetags.image.openshift.io
localresourceaccessreviews.authorization.openshift.io
localsubjectaccessreviews.authorization.k8s.io
localsubjectaccessreviews.authorization.openshift.io
nodes.metrics.k8s.io
packagemanifests.packages.operators.coreos.com
pods.metrics.k8s.io
podsecuritypolicyreviews.security.openshift.io
podsecuritypolicyselfsubjectreviews.security.openshift.io
podsecuritypolicysubjectreviews.security.openshift.io
projects.project.openshift.io
resourceaccessreviews.authorization.openshift.io
rolebindings.authorization.openshift.io
rolebindings.rbac.authorization.k8s.io
roles.authorization.openshift.io
roles.rbac.authorization.k8s.io
selfsubjectaccessreviews.authorization.k8s.io
selfsubjectrulesreviews.authorization.k8s.io
selfsubjectrulesreviews.authorization.openshift.io
subjectaccessreviews.authorization.k8s.io
subjectaccessreviews.authorization.openshift.io
subjectrulesreviews.authorization.openshift.io
tokenreviews.authentication.k8s.io
useridentitymappings.user.openshift.io
)

for NAMESPACE in non-namespaced $(oc get namespace -o template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' ); do

  echo "==> NameSpace: ${NAMESPACE}"
  #mkdir -p ${BASEDIR}/${NAMESPACE}

  if [ "${NAMESPACE}" = "non-namespaced" ]; then
    NAMESPACED="false"
    OC_ARGS=( )
  else
    NAMESPACED="true"
    OC_ARGS=( -n ${NAMESPACE} )
  fi

  for API_OBJECT in $(oc ${OC_ARGS[@]} api-resources --namespaced=${NAMESPACED} -o name); do

    if [[ " ${UNSUPPORTED_TYPES[@]} " =~ " ${API_OBJECT} " ]]; then
      echo "--> Namespace: ${NAMESPACE}, Type: ${API_OBJECT} - Unsupported, Skipping..."
      continue
    fi

    echo "--> Namespace: ${NAMESPACE}, Type: ${API_OBJECT}"
    for RESOURCE in $(oc ${OC_ARGS[@]} get ${API_OBJECT} -o template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' ); do
      echo "--> Namespace: ${NAMESPACE}, Object: ${API_OBJECT}/${RESOURCE}"
      mkdir -p ${BASEDIR}/${NAMESPACE}/${API_OBJECT}/
      oc ${OC_ARGS[@]} get -o ${FORMAT} --export "${API_OBJECT}/${RESOURCE}" > ${BASEDIR}/${NAMESPACE}/${API_OBJECT}/${API_OBJECT}__${RESOURCE}.${FORMAT}
    done
  done
done
