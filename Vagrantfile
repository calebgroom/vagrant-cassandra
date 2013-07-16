# -*- mode: ruby -*-
# vi: set ft=ruby :

## Cassandra cluster settings
server_count = 3
network = '192.168.2.'
first_ip = 10

servers = []
seeds = []
cassandra_tokens = []
(0..server_count-1).each do |i|
  name = 'node' + (i + 1).to_s
  ip = network + (first_ip + i).to_s
  seeds << ip
  servers << {'name' => name,
              'ip' => ip,
              'initial_token' => 2**127 / server_count * i}
end

Vagrant::Config.run do |config|
  servers.each do |server|
    config.vm.define server['name'] do |config2|
      config2.vm.box = "precise"
      config2.vm.box_url = "http://files.vagrantup.com/precise64.box"
      config2.vm.host_name = server['name']
      config2.vm.network :hostonly, server['ip']
      config2.vm.provision :shell, :inline => "gem install chef --version 11.4.2 --no-rdoc --no-ri --conservative"
      config2.vm.provision :chef_solo do |chef|
        chef.log_level = :debug
        chef.cookbooks_path = ["vagrant/cookbooks", "vagrant/site-cookbooks"]
        chef.add_recipe "updater"
        chef.add_recipe "java"
        chef.add_recipe "cassandra::tarball"
        chef.json = {
          :cassandra => {'cluster_name' => 'My Cluster',
                         'initial_token' => server['initial_token'],
                         'seeds' => seeds.join(","),
                         'listen_address' => server['ip'],
                         'rpc_address' => server['ip']}
        }
      end
    end
  end
end
