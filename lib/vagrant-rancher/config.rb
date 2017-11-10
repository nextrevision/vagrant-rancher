module VagrantPlugins
  module Rancher
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :role
      attr_accessor :version
      attr_accessor :hostname
      attr_accessor :port
      attr_accessor :deactivate
      attr_accessor :rancher_server_image
      attr_accessor :server_args
      attr_accessor :agent_args
      attr_accessor :install_agent
      attr_accessor :labels
      attr_accessor :project
      attr_accessor :project_type

      def initialize
        @role = UNSET_VALUE
        @version = UNSET_VALUE
        @hostname = UNSET_VALUE
        @port = UNSET_VALUE
        @rancher_server_image = UNSET_VALUE
        @server_args = UNSET_VALUE
        @agent_args = UNSET_VALUE
        @install_agent = UNSET_VALUE
        @labels = UNSET_VALUE
        @deactivate = UNSET_VALUE
        @project = UNSET_VALUE
        @project_type = UNSET_VALUE
      end

      def finalize!
        @role = 'server' if @role == UNSET_VALUE
        @version = 'latest' if @version == UNSET_VALUE
        @hostname = nil if @hostname == UNSET_VALUE
        @port = 8080 if @port == UNSET_VALUE
        @rancher_server_image = 'rancher/server' if @rancher_server_image == UNSET_VALUE
        @server_args = nil if @server_args == UNSET_VALUE
        @agent_args = nil if @agent_args == UNSET_VALUE
        @install_agent = true if @install_agent == UNSET_VALUE
        @labels = nil if @labels == UNSET_VALUE
        @deactivate = false if @deactivate == UNSET_VALUE
        @project = 'Default' if @project == UNSET_VALUE
        @project_type = 'cattle' if @project_type == UNSET_VALUE
      end

      def validate(_machine)
        errors = _detected_errors

        unless role == 'server' || role == 'agent'
          errors << ':rancher provisioner requires role to either be "server" or "agent"'
        end

        unless version.is_a?(String) || version.nil?
          errors << ':rancher provisioner requires version to be a string'
        end

        unless hostname.is_a?(String)
          errors << ':rancher provisioner requires hostname to be set to a string'
        end

        unless port.is_a?(Fixnum) || port.is_a?(Fixnum)
          errors << ':rancher provisioner requires port to be a number'
        end

        unless rancher_server_image.is_a?(String) || rancher_server_image.nil?
          errors << ':rancher provisioner requires rancher_server_image to be a string'
        end

        unless server_args.is_a?(String) || server_args.nil?
          errors << ':rancher provisioner requires server_args to be a string'
        end

        unless agent_args.is_a?(String) || agent_args.nil?
          errors << ':rancher provisioner requires agent_args to be a string'
        end

        unless install_agent.is_a?(TrueClass) || install_agent.is_a?(FalseClass)
          errors << ':rancher provisioner requires install_agent to be a bool'
        end

        unless labels.is_a?(Array) || labels.nil?
          errors << ':rancher provisioner requires labels to be an array'
        end

        unless deactivate.is_a?(TrueClass) || deactivate.is_a?(FalseClass)
          errors << ':rancher provisioner requires deactivate to be a bool'
        end

        unless project.is_a?(String) || project.nil?
          errors << ':rancher provisioner requires project to be a string'
        end

        unless ['cattle', 'kubernetes', 'swarm'].include? project_type || project_type.nil?
          errors << ':rancher provisioner requires project_type to be one of cattle, kubernetes or swarm'
        end

        { 'rancher provisioner' => errors }
      end
    end
  end
end
