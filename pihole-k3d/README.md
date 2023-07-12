# Intro

A simple example that deploys pihole on k3d single node cluster.

To install k3d and kubectl follow instructions on [k3d.io](https://k3d.io/)

This example exposes pihole to the local network on the ip address provided in config file. Config file list the variables that are used to deploy the application. Make changes to config as required before executing. 

## RUN

 - Make local directory for the data persistence
        e.g /mnt/data/pihole
   - Provide details in config file to be used for deploying the application
   - Execute run.sh script.
   - Access webgui at  http://ip-address/admin 


### Side kicks

Docker network bridge (Macvlan) is created to expose the services to local network. It limits the communication between the host and the containers running on this network bridge. Following cammands can be used to supplement host <-> containers communications.


  ip link add host-cntr link eth0 type macvlan mode bridge
  ip addr add 192.168.1.X/X dev host-cntr
  ip l set host-cntr up
  ip route add 192.168.1.X/X dev host-cntr
 
 update /etc/hosts to resolve the server name