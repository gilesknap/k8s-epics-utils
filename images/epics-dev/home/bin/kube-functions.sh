#!/bin/bash

export k8sdir=$(realpath $(dirname ${BASH_SOURCE[0]}))

if [  "$0" == "${BASH_SOURCE[0]}" ]
then
  echo "you must source this script for it to work correctly"
  exit 1
fi

if [[ -z "$K8S_HELM_REGISTRY" ]] ; then
    echo please set the environment variables K8S_IMAGE_REGISTRY
    echo to point to the URL of the HELM registry in which IOC charts are held
    exit 1
fi

export HELM_EXPERIMENTAL_OCI=1
source <(helm completion bash)
source <(kubectl completion bash)

alias k=kubectl
complete -F __start_kubectl k

###########################################################################
# some helper functions for ioc management
###########################################################################

function kube-ioc-deploy()
{
    (
    set -e

    IOC_NAME=${1}
    VERSION=${2}
    if [ -z "${VERSION}" ]; then VERSION=latest; fi

    BL_PREFIX=${IOC_NAME%%-*}
    IOC_HELM=${K8S_HELM_REGISTRY}/${IOC_NAME}

    # pull the requested ioc helm chart from the registry
    echo getting ${IOC_HELM}:${VERSION}
    helm chart pull ${IOC_HELM}:${VERSION}
    # export it to a folder
    helm chart export ${IOC_HELM}:${VERSION} -d /tmp
    helm dependencies update /tmp/${IOC_NAME}

    # deploy the exported helm chart
    helm upgrade --install ${IOC_NAME}  /tmp/${IOC_NAME}
    rm -r /tmp/${IOC_NAME}
    )
}

# kubectl format strings
export pods="custom-columns=IOC:metadata.name,VERSION:metadata.labels.ioc_version,STATE:status.containerStatuses[0].state.*.reason,RESTARTS:status.containerStatuses[0].restartCount,STARTED:metadata.managedFields[0].time,IP:status.podIP,IMAGE:spec.containers[0].image"
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
        helm delete ${ioc}
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
        ioc=${1:? "param 1 should be an ioc e.g. bl45p-mo-ioc-01"}; shift
        echo "${K8S_GRAYLOG_URL}/search?rangetype=relative&fields=message%2Csource&width=1489&highlightMessage=&relative=172800&q=pod_name%3A${ioc}*"
        ;;

    h|history)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        helm history ${ioc}
        ;;

    list)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl get all -l app=${ioc} ${*}; echo
        # if there is no autosave then there may be no pvcs so ignore errors
        kubectl get pvc -l app=${ioc} ${*} 2> /dev/null
        ;;

    l|log)
        ioc=${1:? "param 1 should be ioc e.g. bl45p-mo-ioc-01"}; shift
        kubectl logs deployment.apps/${ioc} ${*}
        ;;

    m|monitor)
        bl=${1:? "param 1 should be a beamline e.g. bl45p"}; shift
        watch -n0.5 -x -c bash -c "beamline-k8s ${bl} ${*}"
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
                    print a URL to get to greylog historical logging for an ioc
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
        "
        ;;
    esac
}

# run most recently built image in the cache - including part build failures
function run_last()
{
    docker run ${@} -it --user root $(docker images | awk '{print $3}' | awk 'NR==2')
}

export -f run_last
export -f kube-ioc-deploy
export -f beamline-k8s
export -f k8s-ioc
