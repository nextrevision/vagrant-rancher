require 'net/http'
require 'json'

module VagrantPlugins
  module Rancher
    class RancherClient
      def initialize(hostname, port)
        @hostname = hostname
        @port = port
      end

      # waits for the rancher api to come online
      def wait_for_api
        uri = URI "http://#{@hostname}:#{@port}/v1"

        15.times do |i|
          begin
            Net::HTTP.get_response uri
            break
          rescue
            return false if i == 15
            sleep 10
          end
        end

        true
      end

      # waits for the agent to register the host
      def wait_for_agent(project_id, machine_id)
        15.times do |i|
          host = self.get_host project_id, machine_id
          break unless host.nil?
          return false if i == 15
          sleep 10
        end

        true
      end

      # retrieves the Default project id
      def get_project_id(name)
        project_id = nil

        response = self.api '/v1/projects'

        unless response.nil? or response['data'].empty?
          response['data'].each do |project|
            if project['name'] == name
              project_id = project['id']
            end
          end
        end

        project_id
      end

      # retrieves and returns a project object
      def get_project(project_id)
        return self.api "/v1/projects/#{project_id}"
      end

      # retrieves and returns the id of the admin user
      def get_admin_id
        response = self.api '/v1/accounts?name=admin&kind=admin'
        return response['data'][0]['id']
      end

      # retrieves a rancher host object
      def get_host(project_id, machine_id)
        host = nil

        response = self.api "/v1/projects/#{project_id}/hosts"

        unless response.nil? or response['data'].empty?
          response['data'].each do |h|
            host = h if h['labels'].values.include? machine_id
          end
        end

        host
      end

      # retrieves a registration token for a project
      def get_registration_token(project_id)
        headers = { 'x-api-project-id' => project_id }
        response = self.api '/v1/registrationtokens/', 'GET', headers

        return response['data'][0] unless response['data'].empty?
        nil
      end

      # creates a new project
      def create_project(name, type='cattle')
        swarm = false
        kubernetes = false

        case type
        when 'kubernetes'
          kubernetes = true
        when 'swarm'
          swarm = true
        end

        data = {
          'name'       => name,
          'swarm'      => swarm,
          'kubernetes' => kubernetes,
          'publicDns'  => false,
          'members'    => []
        }
        return self.api '/v1/project/', 'POST', nil, data
      end

      # sets the default project for a user
      def set_default_project(user_id, project_id)
        response = self.api "/v1/userpreferences?accountId=#{user_id}&name=defaultProjectId"

        data = {
          'name'      => 'defaultProjectId',
          'value'     => project_id,
          'kind'      => 'userPreference',
          'type'      => 'userPreference',
          'accountId' => user_id,
        }

        if response['data'].empty?
          self.api '/v1/userpreferences/', 'POST', nil, data
        else
          preference_id = response['data'][0]['id']
          self.api "/v1/userpreferences/#{preference_id}/?action=update", 'POST', nil, data
        end
      end

      # deletes a project
      def delete_project(project_id)
        self.api "/v1/projects/#{project_id}/?action=delete", 'POST'
        sleep 2
        self.api "/v1/projects/#{project_id}/?action=purge", 'POST'
      end

      # creates a registration token for a project
      def create_registration_token(project_id)
        headers = { 'x-api-project-id' => project_id }
        self.api '/v1/registrationtokens/', 'POST', headers
      end

      # configures rancher settings
      def configure_setting(setting, value)
        self.api "/v1/activesettings/#{setting}", 'PUT', nil, 'value' => value
      end

      # deactivates a host in rancher to avoid being scheduled on
      def deactivate_host(project_id, host_id)
        headers = { 'x-api-project-id' => project_id }
        self.api "/v1/projects/#{project_id}/hosts/#{host_id}/?action=deactivate", 'POST', headers
      end

      protected

      def api(path, type = 'GET', headers = nil, data = nil)
        # define the connection uri to the rancher server
        uri = URI("http://#{@hostname}:#{@port}#{path}")

        # cheap throttle to avoid connection errors due
        # to too many requests in a short time
        sleep 0.1

        # attempt to start the http connection
        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
            case type
            when 'GET'
              request = Net::HTTP::Get.new uri.request_uri
            when 'POST'
              request = Net::HTTP::Post.new uri.request_uri
              request['Accept'] = 'application/json'
              request['Content-Type'] = 'application/json'
              data = {} if data.nil?
            when 'PUT'
              request = Net::HTTP::Put.new uri.request_uri
              request['Accept'] = 'application/json'
              request['Content-Type'] = 'application/json'
              data = {} if data.nil?
            end

            # set any supplied headers
            unless headers.nil?
              headers.each do |key, value|
                request.add_field key, value
              end
            end

            # set data for the request
            unless data.nil?
              request.set_form_data data
            end

            # make the request
            response = http.request request

            # if the response code is not 2xx, then errror
            unless response.code =~ /20[0-9]/
              raise Errors::HttpResponseCode,
                :method => type,
                :host => @hostname,
                :port => @port,
                :path => path,
                :code => response.code,
                :error => response.body
            end

            # parse the JSON response and return an object
            return JSON.parse response.body
          end
        rescue Exception => e
          raise Errors::ApiConnectionError,
            :host => @hostname,
            :port => @port,
            :error => e.message
        end
      end
    end
  end
end
