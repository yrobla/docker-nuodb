#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

DEFAULT_ROUTE=$(/sbin/ip route | awk '/default/ { print $3 }')

start_nuoagent() {
    sudo -u nuodb /bin/bash -c "SHELL=/bin/bash java -jar /opt/nuodb/jar/nuoagent.jar --broker &> /var/log/nuodb/agent.log &"
    STATUS=1
    while [[ STATUS -ne 0 ]]; do
        echo "=> Waiting for nuoagent service startup"
        sleep 2
        /opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain hosts"
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

stop_console() {
    PID=$(ps -ef | grep "nuodbwebconsole" | grep -v grep| awk '{print $2}')
    kill -9 $PID &>/dev/null
    echo "=> Nuodbwebconsole stopped"
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

start_nuoagent

echo "=> Starting configuration"
SUMMARY=$(/opt/nuodb/bin/nuodbmgr --broker localhost --user $DOMAIN_USER --password ${DOMAIN_PASSWORD:-$RAND_DOMAIN_PASSWORD} --command "show domain summary")

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
echo "    [webconsole] localhost:8080"
echo "=========================================================================================="
echo ""

# launch parts
start_nuoagent
start_console

# prevent container to stop
while true; do
    sleep 1
done

