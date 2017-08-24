#
# Cookbook Name:: mysql-ha
# Recipe:: haproxy
#

# Add an option to disable HAProxy installation
# Set the MySQL port accordindly
if node['haproxy']['disable'] == 'true'
  log("HAProxy will not be installed or configured.")
  node.default['mysql']['port'] = 3306
else
  node.default['mysql']['port'] = 3305
  # Check for valid haproxy attributes on node
  if !node['haproxy'] || node['haproxy'].empty? || !node['haproxy']['role'] || node['haproxy']['role'].empty?
    Chef::Application.fatal!("HAProxy attributes were not set on the node. Please add them.")
  end

  yum_package 'haproxy' do
    action :install
  end
  # Allow haproxy to bind to any port
  bash 'haproxy bind free' do
    user 'root'
    cwd '/tmp'
    code <<-EOH
      setsebool -P haproxy_connect_any 1
    EOH
  end

  template '/etc/haproxy/haproxy.cfg' do
    source 'haproxy.cfg.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables({
      :environment => node.chef_environment
    })
    notifies :enable, "service[haproxy]", :immediately
    notifies :restart, "service[haproxy]", :immediately
  end

  service 'haproxy' do
    supports :status => true, :restart => true, :reload => true
    action :nothing
  end
end