# Quick Start

This specific dev environment was designed to create a LAMP stack Oracle Linux 8 server suitable for hosting a Drupal 9+ site.

This repository does also contain some functionality specific to Drupal websites, but they do not always have to be run. You can use the LAMP stack without using the Drupal pieces.

1.  Clone the repo to an appropriate location on your computer by browsing to that location in a terminal and running `git clone git@github.com:ryan-l-robinson/Oracle-Linux-LAMP.git`
1.  Run `vagrant up` from the same folder as the Vagrantfile to build the VM.
1.  Run `vagrant port` to see which host port is mapped to :80 on guest. It should be 8080 if this is the first VM on your computer.
1.  After build complete, visit https://localhost:[hostport] to view the website content.
1.  Run `vagrant ssh` after the build is complete to access the VM, or run `vagrant ssh-config` to get config details that you can use for remote SSH in an editor such as Visual Studio Code.

## Overview

This is a Vagrant instance that you manage using a YAML file.

## Prerequisites

- Vagrant: https://www.vagrantup.com/
- VirtualBox: https://www.virtualbox.org/
- VirtualBox extension pack

## What gets built

Use this Vagrantfile to build a development environment with the following specs:

- Oracle Linux 8.latest
- Apache v.latest
- MySQL with MariaDB v.latest
- PHP 8.0
- Composer v.latest

## Key Settings

- Webroot from host: https://localhost:*hostport*, https://127.0.0.1:*hostport*, any aliases set up through your hosts file + Apache configuration
- DB Name: drupal
- DB User: root
- DB User PW: root
- Website directory: /opt/www/html/[domain]