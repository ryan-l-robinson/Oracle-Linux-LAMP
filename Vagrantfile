# -*- mode: ruby -*-
# vi: set ft=ruby :

# require yaml module
require 'yaml'

# read yaml file
settings = YAML.load_file('conf/settings.yml')

Vagrant.configure('2') do |config|

  # Define VM base box
  config.vm.box = settings['server']['box']
  if settings['server']['box_url']
    config.vm.box_url = settings['server']['box_url']
  end
  config.vm.hostname = settings['server']['name']  

  # Allocate resources for VM
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = settings['server']['ram']
    vb.cpus = settings['server']['cpus']
  end

  # Map ports for VM->Host as per the settings.yml
  # config.vm.network 'forwarded_port', guest: 80, host: 8080
  settings['server']['ports'].each do |ports|
    config.vm.network 'forwarded_port',
    guest: ports['guest'],
    host: ports['host'],
    auto_correct: true
  end

  # Add syncronized folders as per the settings.yml
  # config.vm.synced_folder 'src/', '/var/www/html', create: true
  if settings['synced_folders']
    settings['synced_folders'].each do |folders|
      config.vm.synced_folder folders['src'], folders['dest'], folders['options']
    end
  end

  # Run the provisioning script.
  config.vm.provision "shell", path: "conf/scripts/provision.sh"
    
  end
  