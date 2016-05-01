# syslogeve2mail
Parse syslog for suricata json entries and send an email

## Configuration suricata

You need to configure suricata to send alerts via syslog to your central syslog server:

```ruby
outputs:
  - eve-log:
      enabled: yes
      filetype: syslog
      identity: "suricataids"
      facility: local5
      level: Critical
      types:
        - drop
        - alert:
            payload: yes           # enable dumping payload in Base64
            payload-printable: yes # enable dumping payload in printable (lossy) format
            packet: yes            # enable dumping of packet (without stream segments)
            http: yes
            tls: yes
            ssh: yes
            smtp: yes
            xff:
              enabled: yes         # respect proxy usage
              mode: overwrite      # replace ip by origin
              deployment: forward  # forward request; no reverse proxy
              header: X-Forwarded-For
```

## Install syslogeve2mail

## Configure syslogeve2mail
