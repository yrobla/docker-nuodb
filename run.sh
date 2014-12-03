#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

start_nuoagent() {
    sudo -u nuodb /bin/bash -c "SHELL=/bin/bash java -jar /opt/nuodb/jar/nuoagent.jar --broker &> /var/log/nuodb/agent.log &"
    STATUS=1
    while [[ STATUS -ne 0 ]]; do
        echo "=> Waiting for nuoagent service startup"
        sleep 2
        /opt/nuodb/bin/nuodbmgr --broker $HOST --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain hosts"
        STATUS=$?
    done
    echo "=> Nuoagent started"
}

stop_nuoagent() {
    PID=$(ps -ef | grep "nuoagent" | grep -v grep| awk '{print $2}')
    kill -9 $PID &>/dev/null
    echo "=> Nuoagent stopped"
}

start_console() {
    sudo -u nuodb /bin/bash -c "SHELL=/bin/bash java -jar /opt/nuodb/jar/nuodbwebconsole.jar &> /var/log/nuodb/webconsole.log &"
}

start_autoconsole() {
    sudo -u nuodb /bin/bash -c "SHELL=/bin/bash java -jar /opt/nuodb/jar/nuodb-rest-api.jar server /opt/nuodb/etc/nuodb-rest-api.yml &> /var/log/nuodb/autoconsole.log &"
}

stop_console() {
    PID=$(ps -ef | grep "nuodbwebconsole" | grep -v grep| awk '{print $2}')
    kill -9 $PID &>/dev/null
    echo "=> Nuodbwebconsole stopped"
}

stop_autoconsole() {
    PID=$(ps -ef | grep "nuodb-rest-api" | grep -v grep| awk '{print $2}')
    kill -9 $PID &>/dev/null
    echo "=> Nuodbautoconsole stopped"
}


if [ "$DOMAIN_PASSWORD" = "**Random**" ]; then
    unset DOMAIN_PASSWORD
    RAND_DOMAIN_PASSWORD=$(pwgen -s 12 1)
fi

if [ "$DBA_PASSWORD" = "**Random**" ]; then
    unset DBA_PASSWORD
    RAND_DBA_PASSWORD=$(pwgen -s 12 1)
fi

if [ -f /nuodb-override/default.properties ]; then
    cp /nuodb-override/default.properties /opt/nuodb/etc/default.properties.tpl
fi
rm -f /opt/nuodb/etc/default.properties 
envsubst < "/opt/nuodb/etc/default.properties.tpl" > "/opt/nuodb/etc/default.properties" 
chown nuodb:nuodb /opt/nuodb/etc/default.properties

rm -f /opt/nuodb/etc/webapp.properties
envsubst < "/opt/nuodb/etc/webapp.properties.tpl" > "/opt/nuodb/etc/webapp.properties" 
chown nuodb:nuodb /opt/nuodb/etc/webapp.properties

rm -f /opt/nuodb/etc/nuodb-rest-api.yml
envsubst < "/opt/nuodb/etc/nuodb-rest-api.yml.tpl" > "/opt/nuodb/etc/nuodb-rest-api.yml"
chown nuodb:nuodb /opt/nuodb/etc/nuodb-rest-api.yml

# use marathon to discover peers
PEERS=()
if [ ! -z "$MARATHON_ENDPOINT" ]; then
    # curl the url and check if there is a host
    echo "Discovering configuration from $MARATHON_ENDPOINT"
    HOSTS=`curl -X GET -H "Content-Type: application/json" http://$MARATHON_ENDPOINT/v2/apps/yroblanuodbbroker | grep -Po '"host":".*?[^"]"' | sed 's/^.*://' | sed 's/^"\(.*\)"$/\1/'`
    echo "hosts are $HOSTS"
    for entry in $HOSTS
    do
        if [ "$entry" != "$HOST" ]; then
            echo "I have new peer $entry"
            PEERS+=("$entry")
        fi
    done
fi

# replace peers entry
PEER_STR=$(printf ",%s" "${PEERS[@]}")
PEER_STR=${PEER_STR:1}
if [ -z "$PEER_STR" ]; then
    echo "No peers, remove entry"
    sed -i "s#peer = NUODB_PEERS##g" /opt/nuodb/etc/default.properties
else
    echo "Final peers are $PEER_STR"
    sed -i "s#NUODB_PEERS#$PEER_STR#g" /opt/nuodb/etc/default.properties
fi

start_nuoagent


echo "=> Starting configuration"
SUMMARY=$(/opt/nuodb/bin/nuodbmgr --broker $HOST --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain summary")

stop_nuoagent
echo "=> Done!"

echo ""
echo "=========================================================================================="
echo "You can now connect to this Nuodb Server:"
echo ""
echo "    domain:"
echo "    [user] $DOMAIN_USER"
echo "    [password] ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD}"
echo ""
while IFS= read -r line
do
    echo  "    $line"
done <<< "$SUMMARY"
echo ""
echo "    ecosystem:"
echo "    [webconsole] localhost:8081"
echo "=========================================================================================="
echo ""

# launch parts
if [ $BROKER == 'true' ]; then
    start_autoconsole
    start_console
fi
start_nuoagent

# wait a bit until everything is setup
sleep 10

# we need to receive a list with databases, user, pass in env vars
# format: DATABASE1=user:pass;DATABASE2=user:pass;etc...
DB_LIST=(${DATABASES//;/ })
for DB_ITEM in "${DB_LIST[@]}"; do
    set -- `echo $DB_ITEM | tr '=' ' '`
    DATABASE_NAME=$1
    DB_ACCESS=$2

    set -- `echo $DB_ACCESS | tr ':' ' '`
    DBA_USER=$1
    DBA_PASSWORD=$2

    # check if we need to init the filesystem or not
    INIT_ARCHIVE=true
    if [ -f /opt/nuodb/data/$DATABASE_NAME/.init ]; then
        INIT_ARCHIVE=false
    fi

    # create or restore databases
    if [ -d "/var/opt/nuodb/production-archives/$DATABASE_NAME" ]; then
        # restore
        /opt/nuodb/bin/nuodbmgr --broker $HOST --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command  "restore database dbname $DATABASE_NAME"
    else
        # create
        /opt/nuodb/bin/nuodbmgr --broker $HOST --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command  "create database dbname $DATABASE_NAME template 'Multi Host' dbaUser $DBA_USER dbaPassword $DBA_PASSWORD"
    fi
    sleep 3
done

/bin/sh -c "while true; do sleep 1; done"
