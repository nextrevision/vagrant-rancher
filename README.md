# vagrant-rancher

Vagrant plugin to install a Rancher server and agents on all vagrant guests.

## Installation

```
vagrant plugin install vagrant-rancher
```

## Requirements

* Docker to be intalled and running on the guest (ideally via unix socket)
* Guest to have an IP reachable by the host running the `vagrant` command (for VirtualBox and VMWare, see [private_network](https://www.vagrantup.com/docs/networking/private_network.html))

## Usage

```
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network "private_network", ip: "192.168.33.100"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision :docker
  config.vm.provision "rancher" do |rancher|
    rancher.hostname = "192.168.33.100"
  end
end
```

The `vagrant-rancher` plugin requires the hostname being set to either a DNS name or IP that is reachable by the host running the `vagrant` command.

### Options

* `hostname` (**required**): the DNS name or IP of the rancher server (must be reachable by the host running the `vagrant` command)
* `role` (*optional*, default: `'server'`): either 'server' (to run the Rancher server) or 'agent' to only run the Rancher agent
* `version` (*optional*, default: `'latest'`): version (tag) of the Rancher server container to run
* `port` (*optional*, default: `8080`): port to run the rancher server on in the case of the server, and communicate with in the case of the agent
* `rancher_image_name` (*optional*, default: `rancher/server`): Override default Rancher server image name. Allows for pull from a private registry
* `server_args` (*optional*, default: `''`): additional args to pass to the Docker run command when starting the Rancher server
* `labels` (*optional*, default: `[]`): array of key=value pairs of labels to assign to the agent (ex. ["role=server","env=local"])
* `deactivate` (*optional*, default: `false`): deactivate the host in Rancher to prevent it from being scheduled on
* `project` (*optional*, default: `Default`): the project to start the agent in (project will be created if it doesn't exist)
* `project_type` (*optional*, default: `cattle`): the project type (one of 'cattle', 'swarm', or 'kubernetes')

## Examples

See examples directory. For a quick setup of a Rancher environment running on RancherOS, see [https://github.com/nextrevision/rancheros-vagrant](https://github.com/nextrevision/rancheros-vagrant).

## Providers Tested

* VirtualBox

## Development

```
bundle install
bundle exec vagrant ...
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nextrevision/vagrant-rancher.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

