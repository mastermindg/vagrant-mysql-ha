name		 "mysql-ha"
maintainer       "Ken Jenney"
maintainer_email "me@kenjenney.com"
license          "All rights reserved"
description      "Installs/Configures MySQL with HA"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.1'

depends		'yum'
depends		'mysql2_chef_gem'
depends		'database'
depends 	'yum-mysql-community'
depends 	'selinux'
depends 	'selinux_policy'
