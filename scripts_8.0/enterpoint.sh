#!/bin/bash


# log function
function log() {
    local time=$(date +"%F %T")
    echo "$time $1 "
    echo "[$time] $1 " &>> /opt/seafile/logs/enterpoint.log
}


# check nginx
while [ 1 ]; do
    process_num=$(ps -ef | grep "/usr/sbin/nginx" | grep -v "grep" | wc -l)
    if [ $process_num -eq 0 ]; then
        log "Waiting Nginx"
        sleep 0.2
    else
        log "Nginx ready"
        break
    fi
done

if [ -z "$PUID" ]; then
    export PUID=$(id -u seafile)
elif [ "$(id -u seafile)" -ne "${PUID}" ]; then
    log "Updating UID to $PUID"
    usermod -u $PUID seafile
fi

if [ -z "$PGID" ]; then
    export PGID=$(id -g seafile)
elif [ "$(id -g seafile)" -ne "${PGID}" ]; then
    log "Updating GID to $PGID"
    groupmod -g $PGID seafile
fi

chown -R seafile:seafile /opt/seafile
chown -R seafile:seafile /scripts
chown -R seafile:seafile /templates
chown -R seafile:seafile /shared
mkdir -p /bootstrap
chown -R seafile:seafile /bootstrap
chown -R :seafile /etc/nginx/sites-enabled
chmod 775 -R /etc/nginx/sites-enabled

# start cluster server
if [[ $CLUSTER_SERVER == "true" && $SEAFILE_SERVER == "seafile-pro-server" ]] ;then
    su seafile -pPc /scripts/cluster_server.sh enterpoint &

# start server
else
    su seafile -pPc /scripts/start.py &
fi


log "This is a idle script (infinite loop) to keep container running."

function cleanup() {
    kill -s SIGTERM $!
    exit 0
}

trap cleanup SIGINT SIGTERM

while [ 1 ]; do
    sleep 60 &
    wait $!
done
