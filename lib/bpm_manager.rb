require "bpm_manager/version"
require "rest-client"
require "json"

module BpmManager
  class << self
    attr_accessor :configuration
  end

  # Defines the Configuration for the gem
  class Configuration
    attr_accessor :bpm_vendor, :bpm_url, :bpm_username, :bpm_password, :bpm_use_ssl
    
    def initialize
      @bpm_vendor = ""
      @bpm_url = ""
      @bpm_username = ""
      @bpm_password = ""
      @bpm_use_ssl = false
    end
  end

  # Generates a new configuration
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
  
  # Returns the URI for the server plus a suffix
  def self.uri(suffix = '')
    case configuration.bpm_vendor.downcase
      when 'redhat'
        URI.encode('http' + (configuration.bpm_use_ssl ? 's' : '') + '://' + configuration.bpm_username + ':' + configuration.bpm_password + '@' + configuration.bpm_url + '/business-central/rest' + (suffix.nil? ? '' : suffix))
      else
        ''
    end
  end

  # Gets all server deployments
  def self.deployments()
    return JSON.parse(RestClient.get(BpmManager.uri('/deployment'), :accept => :json))
  end

  # Gets all server deployments
  def self.tasks(user_id = "")
    return JSON.parse(RestClient.get(BpmManager.uri('/task/query' + (user_id.empty? ? '' : '?taskOwner=' + user_id)), :accept => :json))
  end

  # Gets all server deployments
  def self.tasks_with_opts(opts = {})
    return JSON.parse(RestClient.get(BpmManager.uri('/task/query' + (opts.empty? ? '' : '?' + opts.map{|k,v| puts k.to_s + '=' + v.to_s}.join('&'))), :accept => :json))
  end
end
