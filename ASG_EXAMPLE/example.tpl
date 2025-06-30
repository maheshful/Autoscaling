#!/bin/sh
set -x

/usr/bin/sudo yum install docker git -y
hostnamectl set-hostname ${hostname}


INSTANCE_NAME=$(aws ec2 describe-instances --region eu-west-2 --filters Name=instance-id,Values=$(wget -qO- http://169.254.169.254/latest/meta-data/instance-id) --query Reservations[].Instances[].Tags[].Value --output text)

UNATTACHED=$(/bin/aws ec2 describe-volumes --region eu-west-2 --query 'Volumes[?State==`available`].{ID: VolumeId, State: State, Tag: Tags }' --output text | /bin/grep -i "asg-ebs-persistent" > /tmp/volumes)


INSTANCE_ID=$(/bin/curl http://169.254.169.254/latest/meta-data/instance-id)


for x in {h..z}
do

while IFS= read -r line
do
  VOLUME_ID=`echo $line | cut -d" " -f1`
  /bin/aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device /dev/sd$x 2> /dev/null
done < "/tmp/volumes"

done

function log {
  local level="$1"
  local message=("${@:2}")

  case "$level" in
    error)  echo "$(basename $0): $(date '+%d-%m-%Y_%H:%M:%S')" $'\033[0;31m' "ERROR" $'\033[0m' "${message[*]}" ;;
    debug)  echo "$(basename $0): $(date '+%d-%m-%Y_%H:%M:%S')" $'\033[0;33m' "DEBUG" $'\033[0m' "${message[*]}" ;;
    warn)   echo "$(basename $0): $(date '+%d-%m-%Y_%H:%M:%S')" $'\033[0;33m' "WARN" $'\033[0m' "${message[*]}" ;;
    info)   echo "$(basename $0): $(date '+%d-%m-%Y_%H:%M:%S')" $'\033[0;32m' "INFO" $'\033[0m' "${message[*]}" ;;
    *)   echo "$(basename $0): $(date '+%d-%m-%Y_%H:%M:%S')" "${message[*]}" >&2 ;;
  esac
}

scan_for_new_disks() {
    declare -g NEW_DATA_DISK
    DEVS=($(ls -1 /dev/nvme[0-9]n1*|egrep -v "${BLACKLIST}"|egrep -v "p[0-9]$"))
    for DEV in "${DEVS[@]}";
    do
        if [ ! -b ${DEV}p1 ];
        then
            NEW_DATA_DISK+=("${DEV}")
        fi
    done
}

is_partitioned() {
    log debug "${1}"
    [[ -b "${1}p1" ]]
    return "${?}"
}

do_partition() {
    DISK=${1}
    /bin/echo -e "o\nn\np\n1\n\n\nw" | /sbin/fdisk ${DISK}
    sleep 5
    if [ $? -ne 0 ];
    then
        log error "An error occurred partitioning ${DISK}" >&2
        log error "I cannot continue" >&2
        exit 2
    fi
    log info "Successfully partitioned disk ${DISK}"
}

has_filesystem() {
    DEVICE=${1}
    OUTPUT=$(file -L -s ${DEVICE})
    grep filesystem <<< "${OUTPUT}" > /dev/null 2>&1
    return ${?}
}

has_label()
{
  DEVICE=${1}
  OUTPUT=$(lsblk -o LABEL ${DEVICE} -n)
  grep ds <<< "${OUTPUT}" > /dev/null 2>&1
  return ${?}
}

log info "Script $(basename $0) started.."
ROOT_DISK=$(df / | awk '/nvme/ {print $1}')
ROOT_DISK=$(echo ${ROOT_DISK::-2} | sed s'|/dev/||')
LVM_DISK=$(pvs --noheadings| awk '{print $1}' | sed s'|/dev/||')
BLACKLIST="${ROOT_DISK}|${LVM_DISK}"
DATA_DISK_LABEL=( asg_data ) # Note: The order of the labels matters

log info "Root Volume: ${ROOT_DISK}"
log info "Standard OS Volume: ${LVM_DISK}"
log info "Skipping root & standard volume - ${BLACKLIST}"
sync;sync;sync
/sbin/partprobe
sleep 20
scan_for_new_disks

if [ ${#NEW_DATA_DISK[@]} -eq 0 ]; then
    log warn "No new disk detected.exiting.."
else
    log info "New disks detected ${NEW_DATA_DISK[*]}"
fi

for DISK in "${NEW_DATA_DISK[@]}"
do
    log info "Working on ${DISK}"
    if [[ $(/bin/mount | grep -q "${DISK}") ]]; then
        log warn "Block device ${DISK} already mounted"
        contine
    fi
    is_partitioned "${DISK}"
    if [ ${?} -ne 0 ];
    then
        log info "${DISK} is not partitioned, partitioning"
        do_partition ${DISK}
    fi
    PARTITION=$(fdisk -l ${DISK}|grep -A 1 Device|tail -n 1|awk '{print $1}')
    has_filesystem "${PARTITION}"
    if [ ${?} -ne 0 ];
    then
        log info "Creating filesystem on ${PARTITION}."
        /sbin/mkfs.xfs -q "${PARTITION}"
        /sbin/partprobe
        sleep 15
        log info "Checking filesystem labels"
        for label in "${DATA_DISK_LABEL[@]}"
            do
                if ! blkid | grep "${label}"
                then
                    has_label "${PARTITION}"
                    if [ ${?} -ne 0 ];
                    then
                        /sbin/xfs_admin -L "${label}" "${PARTITION}"
                        log info "Success - label ${label} created on ${PARTITION}"
                        /sbin/partprobe
                        sleep 10
                        break
                    else
                        log warn "Already labelled, Requires attention.Skipping ${PARTITION}"
                    fi
                else
                    log warn "Label already in use ${label} - , checking next available label"
                fi
        done
    else
        log warn "File system already available on ${PARTITION}.Requires attention"
        exit 2
    fi
done
sync;sync;sync
/sbin/partprobe
sleep 10
lsblk -f
log info "Script $(basename $0) completed"