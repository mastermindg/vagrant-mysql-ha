# vagrant-mysql-ha

Custom MySQL Cookbook that provides High Availablility with a master-slave MySQL pair. The servers are provisioned with Chef.

Make sure to install the latest Chef DK, Vagrant, and VirtualBox (for local testing) to get this working.

This has been tested with Chef DK 2.1, Vagrant 1.9.7, and Virtualbox 5.1.26 on OSX 10+ and Ubuntu 16.04+.

This installs on CentOS 7. The box version is locked to ensure replicability.

To get working:

```
git clone https://github.com/mastermindg/vagrant-mysql-ha
cd vagrant-mysql-ha
vagrant up
```
