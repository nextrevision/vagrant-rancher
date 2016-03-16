module VagrantPlugins
  module Rancher
    lib_path = Pathname.new(File.expand_path('../vagrant-rancher', __FILE__))
    autoload :Errors, lib_path.join('errors')

    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end

require 'vagrant-rancher/plugin'
