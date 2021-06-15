#!/bin/bash

export k8sdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [  "$0" == "${BASH_SOURCE[0]}" ]
then
  echo "you must source this script for it to work correctly"
  exit 1
fi

export IMAGE_REGISTRY=gcr.io/diamond-privreg/controls
export HELM_REGISTRY=europe-docker.pkg.dev/diamond-privreg
export HELM_EXPERIMENTAL_OCI=1
source <(helm completion bash)
source <(kubectl completion bash)

alias k=kubectl
complete -F __start_kubectl k

###########################################################################
# some helper functions for ioc management
###########################################################################

function helm-login()
{
    # authorise helm
    gcloud auth print-access-token | helm registry login -u oauth2accesstoken \
      --password-stdin ${HELM_REGISTRY}
}

function kube-ioc-deploy()
{
    (
    set -e

    IOC_NAME=${1}
    VERSION=${2}
    if [ -z "${VERSION}" ]; then VERSION=latest; fi

    BL_PREFIX=${IOC_NAME%%-*}
    IOC_HELM=${HELM_REGISTRY}/${BL_PREFIX}-iocs/${IOC_NAME}

    helm-login

    # TODO - not sure we need to pull this, cant we repo add and then install from repo?
    # TODO - see what I do in in k3s-minecraft - but repo add seems to fail with DLS artifacts

    # pull the requested ioc helm chart from the registry
    echo getting ${IOC_HELM}:${VERSION}
    helm chart pull ${IOC_HELM}:${VERSION}
    # export it to a folder
    helm chart export ${IOC_HELM}:${VERSION} -d /tmp

    # deploy the exported helm chart
    helm upgrade --install ${IOC_NAME}  /tmp/${IOC_NAME}
    rm -r /tmp/${IOC_NAME}
    )
}

# kubectl format strings
export pods="custom-columns=IOC:metadata.name,VERSION:metadata.labels.ioc_version,STATE:status.containerStatuses[0].state.*.reason,RESTARTS:status.containerStatuses[0].restartCount,STARTED:metadata.managedFields[1].time,IP:status.podIP"
export deploys="custom-columns=DEPLOYMENT:metadata.labels.app,VERSION:metadata.labels.ioc_version,REPLICAS:spec.replicas,IMAGE:spec.template.spec.containers[0].image"
export services="custom-columns=SERVICE:metadata.labels.app,CLUSTER-IP:spec.clusterIP,EXTERNAL-IP:status.loadBalancer.ingress[0].ip,PORT:spec.ports[*].targetPort"

function beamline-k8s()
{
    if [ -z ${1} ]
    then
      echo please specify a beamline
      return
    fi
    kubectl get deployment -l beamline=${1} -o $deploys; echo
    kubectl get pod -l beamline=${1} -o $pods; echo
    echo configMaps
    kubectl get configmap -l beamline=${1}; echo
    echo Peristent Volume Claims
    kubectl get pvc -l beamline=${1}; echo
}

function k8s-ioc()
{
    action=${1}
    shift

    case ${action} in

    a|attach)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        echo "connecting to ${ioc}. Detach with ^P^Q or stop with ^D"
        kubectl attach -it deployment.apps/${ioc} ${*}
        ;;

    del|delete)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl delete $(kubectl get all -l app=${ioc} -o name)
        ;;

    deploy)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        version=${1:? param 2 should be version e.g. 1.0b1.1}; shift
        kube-ioc-deploy ${ioc} ${version} ${*}
        ;;

    e|exec)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        echo "connecting to bash shell in ${ioc}. Exit with ^D"
        kubectl exec -it deployment.apps/${ioc} ${*} -- bash
        ;;

    g|graylog)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        echo "https://graylog2.diamond.ac.uk/search?rangetype=relative&fields=message%2Csource&width=1489&highlightMessage=&relative=172800&q=namespace_name%3A%22epics-iocs%22+%26%26+pod_name%3A${ioc}*"
        ;;

    h|history)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        helm history ${ioc}
        ;;

    i|iocs)
        beamline=${1:? "param 1 should be beamline e.g. bl45p"}; shift
        gcloud artifacts packages list --repository "${beamline}-iocs" \
            --location europe --project diamond-privreg ${*}
        ;;

    list)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl get all -l app=${ioc} ${*}; echo
        kubectl get pvc -l app=${ioc} ${*}
        ;;

    l|log)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl logs deployment.apps/${ioc} ${*}
        ;;

    m|monitor)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        watch -n0.5 -x -c bash -c "beamline-k8s ${ioc} ${*}"
        ;;

    ps)
        if [ -z ${1} ]
        then
            kubectl get pod -l is_ioc==True -o ${pods}
        else
            kubectl get pod -l beamline==${1} -o ${pods}
        fi
        echo
        ;;

    purge)
        # delete the helm local cache (helm prune is not yet implemented
        # and even remove is hard to use if the resource names are too long
        # to show in 'helm chart list')
        rm -fr ~/.cache/helm/registry/cache/
        ;;

    r|restart)
        # just delete the pod - the deployment spins up a new one
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl delete $(kubectl get pod -l app=${ioc} -o name)
        ;;

    rollback)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        rev=${1:? "param 2 helm revision no. from k8s-ioc history"}; shift
        helm rollback ${ioc} ${rev}
        ;;

    start)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl scale deployment --replicas=1 ${ioc} ${*}
        ;;

    stop)
        ioc=${1:? param 1 should be ioc e.g. bl45p-mo-ioc-01 }; shift
        kubectl scale deployment --replicas=0 ${ioc} ${*}
        ;;

    v|versions)
        ioc=${1:? param 1 should be ioc e.g. bl45p-mo-ioc-01 }; shift
        BL_PREFIX=${ioc%%-*}
        IOC_HELM=${HELM_REGISTRY}/${BL_PREFIX}-iocs/${IOC_NAME}

        gcloud artifacts tags list --repository "${BL_PREFIX}-iocs" \
            --project diamond-privreg --location europe --package ${ioc} ${*}
        ;;

    *)
        echo "
        usage:
          k8s-ioc <command> <options>

          commands:

            attach <ioc-name>
                    attach to a running ioc shell
            delete <ioc-name>
                    delete all ioc resources except storage
            deploy <ioc-name> <ioc-version>
                    deploy an ioc manifest from the beamline helm registry
            exec <ioc-name>
                    execute bash in the ioc's container
            history <ioc-name>
                    list the history of installed versions of an ioc
            graylog <ioc-name>
                    print a URL to get to greylog historical logging for ioc
            iocs beamline
                    list iocs definitions available for deployment
                    use versions command to get individual version info
            list <ioc-name> [options]
                    list k8s resources associtated with ioc-name
                    -o output formatting e.g. -o name
            log <ioc-name> [options]
                    display log of ioc output
                    -p for previous instance
                    -f to attach to output stream
            monitor <beamline>
                    monitor the status of running IOCs on a beamline
            ps [<beamline>]
                    list all running iocs [on beamline]
            purge
                    clear the helm local cache
            restart <ioc-name>
                    restart a running ioc
            rollback <ioc-name> <revision>
                    rollback to a previous revision
                    (see history command for revision numbers)
            start <ioc-name>
                    start a stopped ioc
            stop  <ioc-name>
                    stop a deployed ioc
            versions <ioc-name>
                    list the versions of an ioc in the helm registry
        "
        ;;
    esac
}

function run_last()
{
    docker run -it --user root $(docker images | awk '{print $3}' | awk 'NR==2')
}

export -f kube-ioc-deploy
export -f k8s-ioc
export -f beamline-k8s
export -f helm-login
