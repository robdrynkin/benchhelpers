#!/bin/bash

default_benchbase_url='https://storage.yandexcloud.net/ydb-benchmark-builds/benchbase-ydb.tgz'
ssh_user="$USER"

function nscp() {
    PSSH_IAM_TOKEN=$BASTION_TOKEN nssh --bastion-user $BASTION_USER -u $BASTION_USER scp -p10 "$@"
}
function nrun() {
    PSSH_IAM_TOKEN=$BASTION_TOKEN nssh --bastion-user $BASTION_USER -u $BASTION_USER run -p10 "$@"
}

usage() {
    echo "upload_benchbase.sh --hosts <hosts_file> [--package <benchbase-ydb>] [--package-url <url>] [--user <$ssh_user>]"
    echo "If you don't specify package and package-url, script will download benchbase from $benchbase_url"
}

unique_hosts=

cleanup() {
    if [ -n "$unique_hosts" ]; then
        rm -f $unique_hosts
    fi
}

if ! which nssh >/dev/null; then
    echo "nssh not found, you should install nssh"
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --package)
            shift
            package=$1
            ;;
        --package-url)
            shift
            benchbase_url=$1
            ;;
        --hosts)
            shift
            hosts=$1
            ;;
        --user)
            shift
            ssh_user=$1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -z "$hosts" ]; then
    echo "Hosts file not specified"
    usage
    exit 1
fi

if [[ -n "$package" && -n "$benchbase_url" ]]; then
    echo "You can't specify both package and package-url"
    usage
    exit 1
fi

if [[ -z "$package" && -z "$benchbase_url" ]]; then
    benchbase_url=$default_benchbase_url
fi

if [ ! -f "$hosts" ]; then
    echo "Hosts file $hosts not found"
    exit 1
fi

unique_hosts=`mktemp`
sort -u $hosts > $unique_hosts

trap cleanup EXIT


# dst_home=$HOME
# if [[ -n "$ssh_user" ]]; then
#     host0=`head -n 1 $unique_hosts`
#     dst_home="`ssh $ssh_user@$host0 'echo $HOME'`"
# fi
dst_homes=$(awk 1 ORS=':~ ' $unique_hosts)

if [[ -n "$package" ]]; then
    if [ ! -f "$package" ]; then
        echo "Package $package not found"
        exit 1
    fi

    nscp $package $dst_homes

    # parallel-scp --user $ssh_user -h $unique_hosts $package $dst_home
    if [ $? -ne 0 ]; then
        echo "Failed to upload package $package to hosts $hosts"
        exit 1
    fi
else
    package=`basename $benchbase_url`

    nrun "wget -O $package $benchbase_url" $(cat $unique_hosts)

    if [ $? -ne 0 ]; then
        echo "Failed to download from $benchbase_url to hosts"
        exit 1
    fi
fi

nrun "tar -xzf `basename $package`" $(cat $unique_hosts)
if [ $? -ne 0 ]; then
    echo "Failed to extract package $package on hosts $hosts"
    exit 1
fi
