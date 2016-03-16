module VagrantPlugins
  module Rancher
    module Errors
      class VagrantRancherError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_rancher.errors")
      end

      class DockerConnection < VagrantRancherError
        error_key(:docker_connection)
      end

      class RancherServerContainer < VagrantRancherError
        error_key(:rancher_server_container)
      end

      class RancherAgentContainer < VagrantRancherError
        error_key(:rancher_agent_container)
      end

      class RegistrationTokenMissing < VagrantRancherError
        error_key(:registration_token_missing)
      end

      class ApiConnectionError < VagrantRancherError
        error_key(:api_connection_error)
      end

      class ApiConnectionTimeout < VagrantRancherError
        error_key(:api_connection_timeout)
      end

      class AgentRegistrationTimeout < VagrantRancherError
        error_key(:agent_registration_timeout)
      end

      class HttpResponseCode < VagrantRancherError
        error_key(:http_response_code)
      end

      class ProjectNotFound < VagrantRancherError
        error_key(:project_not_found)
      end

      class HostNotFound < VagrantRancherError
        error_key(:host_not_found)
      end
    end
  end
end
