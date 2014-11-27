docker-nuodb
============

docker container for nuodb database

Ports
-----

Nuodb needs some open ports:

### Mandatory

- `48004`: broker
- `48005`: SM for your database
- `48006`: TE for your database

Except if you set `AUTOMATION` to `false`

- `48007`: SM for `nuodb_system` database
- `48008`: TE for `nuodb_system` database

### Optional

- `48009`: Nuodb web console

Usage
-----

To create the image yrobla/docker-nuodb, execute the following command:

    docker build --rm -t yrobla/docker-nuodb .

To run the image and bind to ports:

    docker run -d -p 48004:48004 -p 48005:48005 -p 48006:48006 -p 48007:48007 -p 48008:48008 -p 48009:48009 yrobla/docker-nuodb

The first time that you run your container, check the logs of the container by running:

    docker logs <CONTAINER_ID>

You will see an output like the following:

    ========================================================================================
    You can now connect to this Nuodb Server:

        domain:
        [user] domain
        [password] bird

        database:
        [user] dba
        [password] bird
        
        Hosts:
        [broker] localhost/127.0.0.1:48004 (DEFAULT_REGION)
        
        ecosystem:
        [webconsole] localhost:48009
    ========================================================================================

Done!

Configuration
-------------

### Environment variables

- `BROKER` (default: `true`): Should this host be a broker?
- `DOMAIN_USER` (default: `domain`): The administrative user for your domain. All nodes should have the same user.
- `DOMAIN_PASSWORD` (default: `bird`): The administrative password for your domain. All nodes should have the same password. If you set value `**Random**` a random password will be generated.
- `DBA_USER` (default: `dba`): The administrative user for you database (see `DATABASE_NAME`).
- `DBA_PASSWORD` (default: `bird`): The administrative password for you database (see `DATABASE_NAME`). If you set value `**Random**` a random password will be generated.
- `AUTOMATION` (default: `false`): Whether to enable automation on the system database. [NuoDB manual](http://dev.nuodb.com).
- `AUTOMATION_BOOTSTRAP` (default: `true`): Should this node bootstrap the system database? See [NuoDB manual](http://dev.nuodb.com).
- `LOG_LEVEL` (default: `INFO`): Valid levels are, from most to least verbose: ALL, FINEST, FINER, FINE, CONFIG, INFO, WARNING, SEVERE, OFF.
- `LICENSE`: Nuodb license to be installed.

### Mounting the database file volume

In order to persist the database data, you can mount a local folder from the host on the container to store the database files. To do so:

    docker run -d -p 48004:48004 -p 48005:48005 -p 48006:48006 -p 48007:48007 -p 48008:48008 -p 48009:48009 -v /path/in/host:/opt/nuodb/data yrobla/docker-nuodb
