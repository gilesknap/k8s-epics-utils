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
    return 1
fi

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
        IOC_HELM=oci://${K8S_HELM_REGISTRY}/${IOC_NAME}

        echo getting ${IOC_HELM}:${VERSION}

        # deploy the exported helm chart
        (
            set -x
            helm upgrade --install ${IOC_NAME} ${IOC_HELM} --version ${VERSION}
        )
    )
}

# kubectl format strings
export podw="custom-columns=IOC:metadata.name,VERSION:metadata.labels.ioc_version,STATE:status.containerStatuses[0].state.*.reason,RESTARTS:status.containerStatuses[0].restartCount,STARTED:metadata.managedFields[0].time,IP:status.podIP,IMAGE:spec.containers[0].image"
export pods="custom-columns=IOC:metadata.labels.app,VERSION:metadata.labels.ioc_version,STATE:status.containerStatuses[0].state.*.reason,RESTARTS:status.containerStatuses[0].restartCount,STARTED:metadata.managedFields[0].time"
export deploys="custom-columns=DEPLOYMENT:metadata.labels.app,VERSION:metadata.labels.ioc_version,REPLICAS:spec.replicas,IMAGE:spec.template.spec.containers[0].image"
export services="custom-columns=SERVICE:metadata.labels.app,CLUSTER-IP:spec.clusterIP,EXTERNAL-IP:status.loadBalancer.ingress[0].ip,PORT:spec.ports[*].targetPort"

function beamline-info()
{
    kubectl get deployment -l beamline=${beamline} -o $deploys; echo
    kubectl get pod -l beamline=${1} -o $pods; echo
    echo configMaps
    kubectl get configmap -l beamline=${beamline}; echo
    echo Peristent Volume Claims
    kubectl get pvc -l beamline=${beamline}; echo 2> /dev/null
    echo Services
    kubectl get service -l beamline=${beamline}; echo 2> /dev/null
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

    b|beamline)
        bl=${1:? "param 1 should be a beamline e.g. bl45p"}; shift
        if [ -z "$(kubectl get namespaces | grep ${bl})" ] ; then
            echo "ERROR: namespace ${bl} does not exist"
            return 1
        fi
        beamline=${bl}
        kubectl config set-context --current --namespace=${bl}
        ;;

    i|info)
        beamline-info
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

    deploylocal)
        ioc=${1:? "param 1 should be name of an ioc helmchart e.g. in iocs folder"}; shift
        # deploy the local helm chart
        helm upgrade --install ${ioc} iocs/${ioc}
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
        watch -n0.5 -x -c bash -c "beamline-info ${bl} ${*}"
        ;;

    ps)
        if [ "${1}" = "-w" ] ; then
            shift
            format=${podw}
        else
            format=${pods}
        fi
        if [ -z ${1} ]; then
            kubectl get pod -l is_ioc==True -o ${format}
        else
            kubectl get pod -l beamline==${1} -o ${format}
        fi
        echo
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
export -f beamline-info
export -f k8s-ioc

# default beamline is p45
k8s-ioc beamline bl45p
