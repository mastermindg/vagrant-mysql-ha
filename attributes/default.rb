#
# Cookbook Name:: mysql-ha
# Attribute:: default
#

############################ MYSQL ##################################

node.default['mysql']['version'] = '5.5'
node.default['mysql']['bind_address'] = "0.0.0.0"
node.default['mysql']['port'] = '3305'
node.default['mysql']['data_dir'] = "/var/lib/mysql"
node.default['mysql']['directories']['log_dir'] = "/var/log/mysql-#{node['mysql']['service_name']}"
node.default['mysql']['security']['chroot'] = false
node.default['mysql']['tunable'] = "OFF"

############################ HAPROXY ##################################

node.default['haproxy']['admin']['address_bind'] = "0.0.0.0"
node.default['haproxy']['user'] = "haproxy"
node.default['haproxy']['group'] = "haproxy"
node.default['haproxy']['global_max_connections'] = 4000
node.default['haproxy']['stats_socket'] = "/var/lib/haproxy/stats"
node.default['haproxy']['stats_priv'] = "user root group root level admin"
node.default['haproxy']['default_mode'] = "http"
node.default['haproxy']['default_retries'] = 3
node.default['haproxy']['timeout']['connect'] = "5s"
node.default['haproxy']['timeout']['client'] = "600s"
node.default['haproxy']['timeout']['server'] = "600s"
node.default['haproxy']['listen_port'] = '3306'
node.default['haproxy']['listen_mode'] = "tcp"
node.default['haproxy']['listen_options'] = ["tcplog","mysql-check user haproxy"]

############################ PACEMAKER ##################################

default['pacemaker']['interface'] = 'eth0'
default['pacemaker']['email_from'] = "keepalived@me.com"
default['pacemaker']['sysctl_options'] = { "net.ipv4.ip_nonlocal_bind" => "1" }
