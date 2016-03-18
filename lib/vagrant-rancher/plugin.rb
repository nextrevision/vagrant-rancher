begin
  require 'vagrant'
rescue LoadError
  raise 'The vagrant-rancher plugin must be run within Vagrant.'
end

module VagrantPlugins
  module Rancher
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-rancher'
      description <<-DESC.gsub(/^ +/, '')
        Vagrant plugin to install a Rancher server
        and agents on all Vagrant guests.
      DESC

      action_hook(:init_i18n, :environment_load) { init_i18n }

      config(:rancher, :provisioner) do
        require_relative 'config'
        Config
      end

      provisioner(:rancher) do
        require_relative 'provisioner'
        Provisioner
      end

      def self.init_i18n
        I18n.load_path << File.expand_path("locales/en.yml", Rancher.source_root)
        I18n.reload!
      end
    end
  end
end
