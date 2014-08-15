#
#   Author: Rohith
#   Date: 2014-05-22 11:07:10 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./')
require 'misc/logging'
require 'misc/utils'
require 'misc/configuration'
require 'render'
require 'providers'

module RundeckNodes
  class Nodes
    include RundeckNodes::Logging
    include RundeckNodes::Utils
    include RundeckNodes::Configuration
    include RundeckNodes::Providers

    def initialize configuration
      # step: validate the configuration file
      @settings = load_configuration( options( configuration ) )
    end

    def render filter = {}
      # step: iterate the clouds (filtering)
      clouds filter[:clouds] do |cloud_name,config|
        debug "list: cloud: #{cloud_name}, provider: #{config['provider']}"
        # step: find a provider for this cloud
        plugin = provider cloud_name, config['provider'], config
        # step: get me a list of the nodes
        debug "list: provider: #{cloud_name}, pulling the hosts from this provider"
        nodes = plugin.list
        # step: append the tags to the nodes
        nodes = append_tags( cloud_name, nodes )
        # step: render the nodes to console
        puts RundeckNodes::Render.new( nodes, settings[:erb] ).render
      end
    end

    private
    def clouds filter = nil, &block
      filter = '.*' unless filter
      settings['clouds'].each_pair do |name,cfg|
        next unless name =~ /#{filter}/
        yield name,cfg if block_given?
      end
    end

    def append_tags name, nodes = []
      return nodes if settings['tags'].nil? or settings['tags'].empty?
      nodes.each do |host|
        # step: add the cloud tag
        host['cloud'] = name
        host['tags']  = [] unless host['tags']
        host['tags'] << name
        settings['tags'].each_pair do |regex,tags|
          debug "hostname: #{host['hostname']}, regex: #{regex}, tags: #{tags.join(', ')}"
          next unless host['hostname'] =~ /#{regex}/
          ( host['tags'] || [] ) << tags
        end
      end
      nodes
    end
  end
end

