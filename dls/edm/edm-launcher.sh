module load gcloud

image=gcr.io/diamond-pubreg/controls/python3/s03_utils/epics/edm:latest
environ="-e DISPLAY=$DISPLAY -e EDMDATAFILES"

volumes="-v /dls_sw/prod:/dls_sw/prod -v /dls_sw/work:/dls_sw/work"
opts="--net=host --rm -ti"
x11opts="-v /dev/dri:/dev/dri --security-opt=label=type:container_runtime_t"

set -x
podman run ${environ} ${x11opts} ${volumes} ${@} ${opts} ${image} edm -x -noedit ${start}
