require_relative 'rancher'
require_relative 'errors'

module VagrantPlugins
  module Rancher
    class Provisioner < Vagrant.plugin('2', :provisioner)
      def initialize(machine, config, rancher = nil)
        super(machine, config)
        @rancher = rancher || RancherClient.new(@config.hostname, @config.port)
      end

      def provision
        self.check_docker

        self.install_server if config.role == 'server'

        self.configure_server
        self.install_agent
        self.configure_agent
      end

      # determines if we can reach the docker daemon
      def check_docker
        unless @machine.communicate.test('sh -c sleep 3; sudo docker info')
          @machine.ui.error 'Could not connect to docker daemon'
          raise Errors::DockerConnection
        end
      end

      # installs the rancher server at the supplied version
      def install_server
        # check to see if the rancher server is already running
        unless @machine.communicate.test('sudo docker inspect rancher-server')
          image = "#{config.rancher_server_image}:#{config.version}"

          # pull rancher server image if its not already there
          image_check_cmd = "sudo docker images | awk '{ print $1\":\"$2 }' | grep -q #{image}"
          unless @machine.communicate.test(image_check_cmd)
            @machine.ui.info "Pulling Rancher server image: #{image}..."
            unless @machine.communicate.sudo("docker pull #{image}")
              @machine.ui.error "Could not pull Rancher server image"
              raise Errors::RancherServerContainer
            end
          end

          @machine.ui.info "Starting server container: #{image}..."

          docker_cmd = "docker run -d -t --name rancher-server -p #{@config.port}:8080"

          # add any user supplied args to the docker command
          unless config.server_args.nil?
            docker_cmd = "#{docker_cmd} #{config.server_args}"
          end

          # start the server and error if there is a failure
          unless @machine.communicate.sudo("#{docker_cmd} #{image}")
            @machine.ui.error 'Could not start Rancher server container'
            raise Errors::RancherServerContainer
          end

          # wait for the server api to come online
          @machine.ui.detail 'Waiting for server API to become available...'
          unless @rancher.wait_for_api
            raise Errors::ApiConnectionTimeout,
              :host => @config.hostname,
              :port => @config.port
          end

          # gratuitous pause for the server api
          sleep 5
        end
      end

      # configures a running server with the required settings
      def configure_server
        # get the specified project
        project_id = @rancher.get_project_id @config.project

        # verify the project is of the correct type
        unless project_id.nil?
          recreate = false
          project = @rancher.get_project project_id
          if project['kubernetes'] and @config.project_type != 'kubernetes'
            recreate = true
          elsif project['swarm'] and @config.project_type != 'swarm'
            recreate = true
          elsif @config.project_type == 'cattle' and (project['kubernetes'] or project['swarm'])
            recreate = true
          end

          # destroy the project and set project_id to nil when
          # the project is not the specified type
          if recreate
            @rancher.delete_project project_id
            project_id = nil
          end
        end

        # create the project if it doesn't exist
        if project_id.nil?
          @machine.ui.detail "Project does not exist, creating now..."
          @rancher.create_project @config.project, @config.project_type
          sleep 2
          project_id = @rancher.get_project_id @config.project
          raise Errors::ProjectNotFound if project_id.nil?
        end

        # set the default project for the admin user
        user_id = @rancher.get_admin_id
        @rancher.set_default_project user_id, project_id

        # attempt to retrieve a registration token, otherwise create one
        unless @rancher.get_registration_token project_id
          @machine.ui.detail "Registration tokens have not been created, creating now..."
          @rancher.create_registration_token project_id

          # set the api.host setting required for agents
          @rancher.configure_setting 'api.host', "http://#{@config.hostname}:#{@config.port}"
          sleep(2)

          # verify that the registration token was created
          raise Errors::RegistrationTokenMissing unless @rancher.get_registration_token project_id
        end
      end

      # runs the agent container on the guest
      def install_agent
        # if the agent container is not running, start it
        unless @machine.communicate.test('sudo docker inspect rancher-agent')
          # retrieve the default project id
          project_id = @rancher.get_project_id @config.project
          raise Errors::ProjectNotFound if project_id.nil?

          # retrieve the registration token
          @machine.ui.detail 'Retrieving agent registration command...'
          registration_token = @rancher.get_registration_token project_id
          raise Errors::RegistrationTokenMissing if registration_token.nil?

          docker_cmd = registration_token['command']

          # apply a default label with the machine id used for
          # checking that the agent has indeed registered the host
          labels = "id=#{@machine.id}"
          # apply and additional host labels
          unless config.labels.nil?
            labels = "#{labels}&#{config.labels.join('&')}"
          end

          extra_args = "-e 'CATTLE_HOST_LABELS=#{labels}' --name rancher-agent-bootstrap"
          docker_cmd = docker_cmd.sub('docker run', "docker run #{extra_args}")

          # pull rancher agent image if its not already there
          image_check_cmd = "sudo docker images | awk '{ print $1\":\"$2 }' | grep -q #{registration_token['image']}"
          unless @machine.communicate.test(image_check_cmd)
            @machine.ui.info "Pulling Rancher agent image: #{registration_token['image']}..."
            unless @machine.communicate.sudo("docker pull #{registration_token['image']}")
              @machine.ui.error "Could not pull Rancher agent image"
              raise Errors::RancherServerContainer
            end
          end

          # start the agent container
          @machine.ui.info "Starting agent container: #{registration_token['image']}..."
          unless @machine.communicate.sudo(docker_cmd)
            @machine.ui.error 'Could not start Rancher agent container'
            raise Errors::RancherAgentContainer
          end

          # wait for the agent to register the host in rancher (checks
          # for the @machine.id in the host labels)
          @machine.ui.detail 'Waiting for agent to register...'
          unless @rancher.wait_for_agent project_id, @machine.id
            raise Errors::AgentRegistrationTimeout,
              :host => @config.hostname,
              :port => @config.port
          end
        end
      end

      # configure the agent in rancher
      def configure_agent
        # retrieve the project id
        project_id = @rancher.get_project_id @config.project
        raise Errors::ProjectNotFound if project_id.nil?

        # retrieve the host by the @machine.id label
        host = @rancher.get_host project_id, @machine.id
        raise Errors::HostNotFound, :project_id => project_id if host.nil?

        # when deactivate is set and the host is active, deactivate it
        if @config.deactivate and host['state'] == 'active'
          @machine.ui.info "Deactivating agent..."
          @rancher.deactivate_host project_id, host['id']
        end
      end
    end
  end
end
