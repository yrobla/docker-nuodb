# NuoDB options
nuoDBConfiguration:
  # NuoDB domain user name. If blank, then Rest Svc will load the NuoDB
  # home ./etc/default.properties and use the "domain" property value.
  username: ${DOMAIN_USER}
  # NuoDB domain user password. If blank, then Rest Svc will load the NuoDB
  # home ./etc/default.properties and use the "domainPassword" property value.
  password: ${DOMAIN_PASSWORD}
  broker: ${HOST}   # NuoDB broker address
  port: 48004         # NuoDB broker port
  metricsCacheEnabled: true
  metricsCacheSize: 20
  metricsCacheExpirySecs: 10

# Logging settings.
# http://dropwizard.codahale.com/manual/core/#logging
logging:

  # The default level of all loggers. Can be OFF, ERROR, WARN, INFO, DEBUG, TRACE, or ALL.
  level: INFO

  console:
    enabled: true
    threshold: INFO

  file:
    enabled: false
    # Do not write log statements below this threshold to the file.
    threshold: INFO
    currentLogFilename: var/log/nuodb/restsvc.log
    archive: false
    # archivedLogFilenamePattern: ./logs/example-%d.log.gz
    # archivedFileCount: 5
    timeZone: UTC

# HTTP options
http:

  # The port on which the HTTP server listens for service requests.
  # Because Java cannot drop privileges in a POSIX system, these
  # ports cannot be in the range 1-1024. A port value of 0 will
  # make the OS use an arbitrary unused port.
  port: 8888

  # The port on which the HTTP server listens for administrative
  # requests. Subject to the same limitations as "port". If this is
  # set to the same value as port, the admin routes will be mounted
  # under /admin.
  adminPort: 8889

  # If specified, adds Basic Authentication to the admin port using
  # this username.
  adminUsername: null

  # If specified, adds Basic Authentication to the admin port using
  # this password. (Requires adminUsername to be specified).
  adminPassword: null
  rootPath: /api/*  # Default is /*

  # web access log
  requestLog:

    console:
      enabled: false
      timeZone: UTC
      logFormat: null

    file:
      enabled: false
      timeZone: UTC
      logFormat: null
      currentLogFilename: ./logs/requests.log
      # archive: true
      # archivedLogFilenamePattern: ./logs/requests-%d.log.gz
      # archivedFileCount: 5


