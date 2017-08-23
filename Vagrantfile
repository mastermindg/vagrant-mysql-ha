# -*- mode: ruby -*-
# vi: set ft=ruby :

box_version = '1707.01'
required_plugins = %w( vagrant-triggers vagrant-share vagrant-omnibus vagrant-hostmanager vagrant-berkshelf vagrant-vbguest)
required_plugins.each do |plugin|
    exec "vagrant plugin install #{plugin};vagrant #{ARGV.join(" ")}" unless Vagrant.has_plugin? plugin || ARGV[0] == 'plugin'
end

# Make sure that GuestAdditions are where they need to be
exec "cp /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso /tmp/" unless File.exist?('/tmp/VBoxGuestAdditions.iso')

# Make sure we've got the correct centos/7 version
system("vagrant box add --box-version #{box_version} --provider virtualbox centos/7") unless system("vagrant box list | grep -q #{box_version}")

nodes = {
  primary: {
    hostname: 'mysql-primary',
    ipaddress: '192.168.56.19',
    other_server: '192.168.56.20',
    role: 'MASTER',
    server_id: 1
  },
  secondary: {
    hostname: 'mysql-secondary',
    ipaddress: '192.168.56.20',
    other_server: '192.168.56.19',
    role: 'BACKUP',
    server_id: 2
  }
}

Vagrant.configure(2) do |config|
  netmask = '255.255.255.0'

  config.vm.box = 'centos/7'
  config.vm.box_version = "=#{box_version}"
  config.vm.box_check_update = false

  # Enabling the Berkshelf plugin globally
  config.berkshelf.enabled = true

  # Add IP addresses to /etc/hosts on first run
  config.vm.provision 'shell', inline: 'echo -e "192.168.56.19\tmysql-primary" >> /etc/hosts', run: 'once'
  config.vm.provision 'shell', inline: 'echo -e "192.168.56.20\tmysql-secondary" >> /etc/hosts', run: 'once'

  # Enable Eth1 by default on each run
  config.vm.provision 'shell', inline: 'ifup eth1', run: 'always'

  nodes.each do |node, options|
    role = options[:role]
    hostname = options[:hostname]
    ipaddress = options[:ipaddress]
    server_id = options[:server_id]
    other_server = options[:other_server]

    config.vm.define node do |n_conf|
      n_conf.vm.provider 'virtualbox' do |vb|
        vb.name = "chef-#{hostname}"
        vb.memory = '1024'
        vb.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
      end

      n_conf.vm.network :private_network, ip: ipaddress, netmask: netmask
      if options.key?(:forwardport)
        fwd = options[:forwardport]
        n_conf.vm.network :forwarded_port, guest: fwd[:guest], host: fwd[:host]
      end
      n_conf.vm.hostname = hostname

      n_conf.vm.provision "chef_solo" do |chef|
        chef.node_name = hostname
        chef.cookbooks_path = "./cookbooks"
        chef.nodes_path = "./nodes"
        chef.roles_path = "./roles"
        chef.add_recipe("mysql-ha")
        chef.environments_path = './environments'
        chef.environment = 'test'
        chef.json = {
          "cluster_role" => "#{role}",
          "cluster_name" => "db_test",
          "other_server" => "#{other_server}",
          "servers" => {
            "mysql-primary" => "192.168.56.19",
            "mysql-secondary" => "192.168.56.20"
          },
          "haproxy" => {
            "role" => "#{role}",
            "server" => {
              "backup" => {
                "hostname" => "mysql-secondary",
                "ipaddress" => "192.168.56.20"
              }
            }
          },
          "pacemaker" => {
            "role" => "#{role}",
            "vip" => "192.168.56.21",
            "interface" => "eth1",
          },
          "mysql" => {
            "version" => "5.6",
            "server_id" => "#{server_id}",
            "db_name" => "testdb",
            "root_password" => "password",
            "user_name" => "tester",
            "user_password" => "password",
            "replicator_password" => "password",
            "haproxy_password" => "password"
          }
        }
      end
    end
  end
end
