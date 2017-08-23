#
# Cookbook Name:: mysql-ha
# Recipe:: default
# 

############################ MYSQL ##################################

include_recipe 'mysql-ha::mysql'

############################ HAProxy ##################################

include_recipe 'mysql-ha::haproxy'

############################ Pacemaker ##################################

include_recipe 'mysql-ha::pacemaker'

############################ Percona ##################################

include_recipe 'mysql-ha::percona'
