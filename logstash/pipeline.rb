# DO NOT UPDATE WITHOUT CODE REVIEW
# Raise a PR for any changes here https://github.com/DFE-Digital/tra-shared-services/
#
# 1. Edit the logstash/pipeline.rb file
# 2. Raise a PR
# 3. Once merged, copy/paste the contents of the file, replacing everything below

# Updated 2023-05-26 by malcolm1.baig@education.gov.uk
filter {
# If the event originates from a service hosted in GOVUK PaaS
  if "space_name" in [message] {
    grok {
# Attempt to parse syslog lines
      match => { "message" => "(%{NONNEGINT:message_length} )?%{SYSLOG5424PRI}%{NONNEGINT:syslog_ver} (?:%{TIMESTAMP_ISO8601:syslog_timestamp}|-) +%{DATA:syslog_host} +%{UUID:cf_app_guid} +\[%{DATA:syslog_proc}\] +- +(\[tags@%{NONNEGINT} +%{DATA:cf_tags}\])? +%{GREEDYDATA:syslog_msg}" }

# If successful, save original `@timestamp` and `host` fields created by Logstash
      add_field => [ "received_at", "%{@timestamp}" ]
        add_field => [ "received_from", "%{host}" ]
        tag_on_failure => ["_syslogparsefailure"]
        add_field => [ "raw_message", "%{message}" ]
    }

    if [cf_tags] {
      kv {
        source => "cf_tags"
          target => "cf_tags"
          value_split => "="
      }
    }

# Parse the syslog pri field into severity/facility
    syslog_pri { syslog_pri_field_name => 'syslog5424_pri' }

# Replace @timestamp field with the one from syslog
    date { match => [ "syslog_timestamp", "ISO8601" ] }

# Cloud Foundry passes the app name, space and organisation in the syslog_host
# Filtering them into separate fields makes it easier to query multiple apps in a single Kibana instance
    if [syslog_host] {
      dissect {
        mapping => { "syslog_host" => "%{[cf][org]}.%{[cf][space]}.%{[cf][app]}" }
        tag_on_failure => ["_sysloghostdissectfailure"]
      }
    }

# Cloud Foundry gorouter logs
    if [syslog_proc] =~ "RTR" {
      mutate { replace => { "type" => "gorouter" } }
      grok {
        match => { "syslog_msg" => "%{HOSTNAME:[access][host]} - \[%{TIMESTAMP_ISO8601:router_timestamp}\] \"%{WORD:[access][method]} %{NOTSPACE:[access][url]} HTTP/%{NUMBER:[access][http_version]}\" %{NONNEGINT:[access][response_code]:int} %{NONNEGINT:[access][body_received][bytes]:int} %{NONNEGINT:[access][body_sent][bytes]:int} %{QUOTEDSTRING:[access][referrer]} %{QUOTEDSTRING:[access][agent]} \"%{HOSTPORT:[access][remote_ip_and_port]}\" \"%{HOSTPORT:[access][upstream_ip_and_port]}\" %{GREEDYDATA:router_keys}" }
        tag_on_failure => ["_routerparsefailure"]
          add_tag => ["gorouter"]
      }
# Replace @timestamp field with the one from router access log
      date {
        match => [ "router_timestamp", "ISO8601" ]
      }
      kv {
        source => "router_keys"
          target => "router"
          value_split => ":"
          remove_field => "router_keys"
      }

      mutate {
        convert => {
          "[router][response_time]" => "float"
            "[router][gorouter_time]" => "float"
            "[router][app_index]" => "integer"
        }
      }
    }

# Application logs
    if [syslog_proc] =~ "APP" {
      json {
        source => "syslog_msg"
          add_tag => ["app"]
      }
    }

# User agent parsing
    if [access][agent] {
      useragent {
        source => "[access][agent]"
          target => "[access][user_agent]"
      }
    }

    if !("_syslogparsefailure" in [tags]) {
# If we successfully parsed syslog, replace the message and source_host fields
      mutate {
        rename => [ "syslog_host", "source_host" ]
          rename => [ "syslog_msg", "message" ]
      }
    }

# Drop router logs for DQT API for now
    if [cf_tags][app_name] =~ "qualified-teachers-api" and [syslog_proc] =~ "RTR" {
      drop { }
    }
  } else {
  # Assume the event originated from a service hosted in Azure
  # All TRA apps in Azure currently use the same logging approach and send JSON
  # to Logstash
    json {
      source => "message"
      target => "azure_app"
    }
  }
}
