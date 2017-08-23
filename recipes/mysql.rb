#
# Cookbook Name:: mysql-ha
# Recipe:: mysql
#

# Update repos
include_recipe 'yum'

## SELinux Policies

package 'policycoreutils-python' do
  action :install
end

include_recipe 'selinux_policy::install'

# Allow mysql to bind to mysql port, by giving it the mysqld_port_t context
selinux_policy_port "#{node['mysql']['port']}" do
  protocol 'tcp'
  secontext 'mysqld_port_t'
end

# Separete recipe for testing and data bag selection
## THE MYSQL COOKBOOK USES THE MYSQL COMMUNITY REPO
# Make sure to use the version attribute, currently locked at 5.5

if node['mysql']['version'] == '5.6'
  include_recipe 'yum-mysql-community::mysql56'
elsif node['mysql']['version'] == '5.7'
  include_recipe 'yum-mysql-community::mysql57'
else
  include_recipe 'yum-mysql-community::mysql55'
end

package 'mysql-community-server' do
  action :install
end

service 'mysqld' do
  supports :status => true, :restart => true, :reload => true
  action :nothing
end

# Set additional parameters + replication
if node['mysql']['server_id']
  log "server id: #{node['mysql']['server_id']}"
else
  Chef::Application.fatal!("No mysql server_id set on the node. Please add one.")
end
template '/etc/my.cnf' do
  source 'my.cnf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :enable, "service[mysqld]", :immediately
  notifies :restart, "service[mysqld]", :immediately
end

if node.chef_environment == 'test'
  mysql_root_password = node['mysql']['root_password']
  db_user_password = node['mysql']['user_password']
  db_user_name = node['mysql']['user_name']
  haproxy_password = node['mysql']['haproxy_password']
  replicator_password = node['mysql']['replicator_password']
else
  myhostmysqlusers = begin
    myhostname = node.name.split('.')[0]
    data_bag_item('mysql', myhostname, IO.read('/etc/chef/encrypted_data_bag_secret'))
  rescue Net::HTTPServerException, Chef::Exceptions::InvalidDataBagPath
    nil
  end
  mysql_root_password = myhostmysqlusers["root_password"]
  db_user_password = myhostmysqlusers['user_password']
  db_user_name = myhostmysqlusers['user_name']
  haproxy_password = myhostmysqlusers['haproxy_password']
  replicator_password = myhostmysqlusers['replicator_password']
end

# Install the mysql2 Ruby gem.
mysql2_chef_gem 'default' do
  action :install
end

# Root password is initially blank, set in on the first run
unless node['password_set']
  ## Set the mysql db name in the node attributes
  if node['mysql']['db_name']
    mysql_db_name = node['mysql']['db_name']
  else
    Chef::Application.fatal!("No mysql database name set on the node. Please add one.")
  end

  mysql_connection_info = {
    :socket     => "/var/lib/mysql/mysql.sock",
    :username   => 'root'
  }

  # Create our database and restart to initialize replication
  mysql_database mysql_db_name do
    connection   mysql_connection_info
    action :create
    notifies :restart, "service[mysqld]", :immediately
  end

  # Don't allow root from any other host but localhost
  mysql_database_user 'root' do
    connection    mysql_connection_info
    host          '%'
    action        :drop
  end

  # Allow root locally with password
  mysql_database_user 'root' do
    connection   mysql_connection_info
    password     mysql_root_password
    database_name '*.*'
    host          'localhost'
    action        :grant
  end

  node.normal["password_set"] = true
  log 'Set node attribute password_set now that the MySQL root password has been set'
end

mysql_connection_info = {
    :socket     => "/var/lib/mysql/mysql.sock",
    :username   => 'root',
    :password   => mysql_root_password
  }

# Grant access to db_name by db_user from anywhere with a password
mysql_database_user db_user_name do
  connection mysql_connection_info
  password db_user_password
  action :create
end

mysql_database_user db_user_name do
  connection    mysql_connection_info
  password      db_user_password
  database_name mysql_db_name
  host          '%'
  action        :grant
end


# Allow HAProxy to connect to/from either server
node['servers'].each do |hostname, ip|
  # Grant access to haproxy user for checking connectivity
  mysql_database_user 'haproxy' do
    connection    mysql_connection_info
    password      haproxy_password
    host          hostname
    action        :create
  end

  mysql_database_user 'haproxy' do
    connection    mysql_connection_info
    database_name mysql_db_name
    host          hostname
    action        :grant
  end

  # Grant specific access to db user from each node
  mysql_database_user db_user_name do
    connection    mysql_connection_info
    password      db_user_password
    host          hostname
    action        :create
  end

  mysql_database_user db_user_name do
    connection    mysql_connection_info
    password      db_user_password
    database_name mysql_db_name
    host          hostname
    action        :grant
  end

  # Grant replicator access from each node
  mysql_database_user 'replicator' do
    connection mysql_connection_info
    password replicator_password
    action :create
  end

  mysql_database_user 'replicator' do
    connection    mysql_connection_info
    password      db_user_password
    host          hostname
    action        :grant
  end

  # Allow replication to/from both servers
  bash 'replicate' do
    user 'root'
    cwd '/tmp'
    code <<-EOH
      root_password="#{mysql_root_password}"
      hostname="#{hostname}"
      mysql -u root -p$root_password -e "grant replication slave on *.* to 'replicator'@'$hostname';"
    EOH
  end

  # Get the replication coordinates for both servers
  # 'Other' server ip is stored in an attribute
  if node['cluster_role'] == "BACKUP"
    other_server = node['other_server']
    log "other server ip: #{other_server}"
    bash 'get coordinates' do
      user 'root'
      cwd '/'
      code <<-EOH
        replicator_password="#{replicator_password}"
        other_server="#{other_server}"
        mysql -h $other_server -P 3305 -u replicator -p$replicator_password -e "show master status" > status
      EOH
    end

    if File.exist?('/tmp/status')
      coordinates = ::File.read('/status').chomp
      log "coordinates: #{coordinates}"

      bash 'get coordinates' do
        user 'root'
        cwd '/tmp'
        code <<-EOH
          coordinates="#{coordinates}"
          echo $coordinates
        EOH
      end
    else
      log "File doesn't exist"
    end
  end
end

