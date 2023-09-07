#!/bin/bash

HOSTS_FILE="<PATH_TO_HOSTS_FILE>"

DISKS=(/dev/nvme0n1p2
       /dev/nvme1n1p2
       /dev/nvme2n1p2
       /dev/nvme3n1p2)

CONFIG_DIR="<PATH_TO_CONFIG>"
YDB_SETUP_PATH="/opt/ydb"

GRPC_PORT_BEGIN=2135
IC_PORT_BEGIN=19001
MON_PORT_BEGIN=8765

STATIC_TASKSET_CPU="0-5"

DYNNODE_COUNT=3
DYNNODE_TASKSET_CPU=(6-10 11-15 16-20)

DATABASE_NAME="db"

# <pool type>:<pool size>
STORAGE_POOLS="ssd:1"
