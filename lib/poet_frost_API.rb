require 'net/http'
require 'json'
require 'date'

# Configuration module for use when poet_frost_API is called with include.
# 
# Include PoetFrostAPI and map the API fields to attributes of the local object.
# In the example below, the content field is mapped to the local object's
# body attribute.
#
# Usage example:
# include PoetFrostAPI
#
# poet_frost_configure do |config|
#   config.name = :name # Required
#   config.datePublished = :updated_at
#   config.dateCreated = :created_at
#   config.author = :author # Required
#   config.tags = :tags
#   config.content = :body # Required
#   config.work_id = :workid
#   config.api_key = :frost_api_key
# end
#
# API keys currently need to be manually registered at https://frost.po.et/
#
# In a Rails model like a blog post, you'll want to have :frost_api_key be a
# linked attribute belonging to the user making the post, unless it's a single
# user blog, in which case it might be easier to just set the FROST_TOKEN
# environment variable.
module PoetFrostConfig
  attr_accessor :poet_frost_config

  FROST_API_KEY = ENV['FROST_TOKEN']
  FROST_URI = URI('https://api.frost.po.et/works/')
  FROST_HTTP = Net::HTTP.new(FROST_URI.host, FROST_URI.port)
  FROST_HTTP.use_ssl = true

  def poet_frost_configuration
    @poet_frost_config ||= OpenStruct.new(
      name: nil,
      datePublished: nil,
      dateCreated: nil,
      author: nil,
      tags: nil,
      content: nil,
      api_key: nil,
      work_id: nil
    )
  end

  def poet_frost_configure
    yield(poet_frost_configuration)
  end
end

# To use any of the methods, register an API key at https://frost.po.et/
# and save it as the environment variable FROST_TOKEN.
module PoetFrostAPI

  # When PoetFrostAPI is included, extend the base class with the
  # PoetFrostConfig module.
  def self.included(base)
    base.extend(PoetFrostConfig)
  end

  @@api_key = ENV['FROST_TOKEN']
  @@uri = URI('https://api.frost.po.et/works/')
  @@http = Net::HTTP.new(@@uri.host, @@uri.port)
  @@http.use_ssl = true


  # Register a work on Po.et.
  #
  # Usage:
  # PoetFrostAPI.create_work(name: 'Work Name',
  #                          datePublished: DateTime.now.iso8601,
  #                          dateCreated: DateTime.now.iso8601,
  #                          author: 'Author Name',
  #                          tags: 'Tag1, Tag2',
  #                          content: 'Content body',
  #                          api_key: 'API_key'
  #                          )
  #
  # api_key will default to ENV['FROST_TOKEN'] if omitted
  # datePublished and dateCreated will default to current datetime if omitted
  # tags will default to blank string if omitted
  #
  # Returns a string with the workid that was registered.
  def PoetFrostAPI.create_work(args = {})

    req = Net::HTTP::Post.new(@@uri.path)
    req.content_type = 'application/json'
    args.keep_if { |k, v| [:name,
                           :datePublished,
                           :dateCreated,
                           :author,
                           :tags,
                           :content,
                           :api_key].include?(k) }
    req['token'] = args[:api_key] || @@api_key
    args[:datePublished] ||= DateTime.now.iso8601
    args[:dateCreated] ||= DateTime.now.iso8601
    args[:tags] ||= ''
    req.body = args.to_json
    res = @@http.request(req)
    JSON.parse(res.body)['workId']
  rescue => e
    "failed #{e}"
  end

  # Retrieve a specific work from Po.et, using the workId returned from
  # create_work.
  #
  # Usage:
  # PoetFrostAPI.get_work(workId, api_key: 'API_key')
  #
  # api_key will default to ENV['FROST_TOKEN'] if omitted
  #
  # Returns a hash with the created fields.
  def PoetFrostAPI.get_work(workId, args = {})
    uri = @@uri + workId
    req = Net::HTTP::Get.new(uri.path)
    req.content_type = 'application/json'
    args.keep_if { |k, v| [:api_key].include?(k) }
    req['token'] = args[:api_key] || @@api_key
    res = @@http.request(req)
    JSON.parse(res.body)
  rescue => e
    "failed #{e}"
  end

  # Retrieve all works submitted by your Frost API Token.
  #
  # Usage:
  # PoetFrostAPI.get_all_works(api_key: 'API_key')
  #
  # api_key will default to ENV['FROST_TOKEN'] if omitted
  #
  # Returns an array of individual works (hashes)
  def PoetFrostAPI.get_all_works(args = {})
    req = Net::HTTP::Get.new(@@uri.path)
    req.content_type = 'application/json'
    args.keep_if { |k, v| [:api_key].include?(k) }
    req['token'] = args[:api_key] || @@api_key
    res = @@http.request(req)
    JSON.parse(res.body)
  rescue => e
    "failed #{e}"
  end

  # Post the work to Po.et
  # Usage example:
  # @blog_post.post_to_poet
  #
  # This will post the object's linked fields to Po.et (see the module
  # PoetFrostConfig for configuration)
  #
  # If the class is an ActiveRecord object, and the work_id field is present,
  # the object will be updated with the work_id returned (without altering
  # timestamps).  Otherwise, the method will return the work_id.
  #
  # If the configuration includes an API key field, that will be used when
  # posting.  Otherwise, it will look for and use the environment variable
  # FROST_TOKEN.
  #
  # Dates will default to the current time if not set in config.
  def post_to_poet
    req = Net::HTTP::Post.new(PoetFrostConfig::FROST_URI.path)
    req.content_type = 'application/json'
    args = self.class.poet_frost_config.to_h
    # Go through the config args and pass them on appropriately.
    args.each do |k,v|
      # Ignore undefined values
      if v == nil
        args.delete(k)
      # If the value is a model field, instance_eval it so we can pull in the actual value from the object.
      elsif self.class.method_defined? v
        # Check if the field is a date field and, if so, do .iso8601 on it.
        # If not, pass the field value in as-is.
        if self.instance_eval(v.to_s).class.method_defined? :iso8601
          args[k] = self.instance_eval(v.to_s).iso8601
        else
          args[k] = self.instance_eval(v.to_s)
        end
      # If it isn't a model field, pass the value in directly (as a string)
      # TODO test this
      else
        args[k] = v.to_s
      end
    end
    # Can do away with this after the api starts accepting arbitrary fields
    # Replace it with delete_if to take out work_id.
    args.keep_if { |k, v| [:name,
                           :datePublished,
                           :dateCreated,
                           :author,
                           :tags,
                           :content,
                           :api_key].include?(k) }
    # Use the referenced model field, if set.  Else use the string value, if it exists.  Else use
    # the environment variable.
    # TODO test, such as with a Blog model that belongs_to User, and has user.frost_key set in the config.
    frost_config = self.class.poet_frost_config 
    req['token'] = if self.class.method_defined? frost_config[:api_key].to_s
                     self.instance_eval(frost_config[:api_key])
                   elsif frost_config[:api_key]
                     frost_config[:api_key]
                   else
                     PoetFrostConfig::FROST_API_KEY
                   end
    args.delete(:api_key) if args[:api_key]
    args[:datePublished] ||= DateTime.now.iso8601
    args[:dateCreated] ||= DateTime.now.iso8601
    args[:tags] ||= ''
    req.body = args.to_json
    res = PoetFrostConfig::FROST_HTTP.request(req)
    workid = JSON.parse(res.body)['workId']
    # Check if we're running ActiveRecord, and post_to_poet is being run on an
    # ActiveRecord object.
    if defined?(ActiveRecord::Base) && self.is_a?(ActiveRecord::Base)
      # Check if work_id is defined
      if self.class.poet_frost_config.work_id
        # Update the work_id column with the workId, preserve original timestamps.
        work_id_column = self.class.poet_frost_config.work_id
        self.update_column(work_id_column, workid)
      end
      # If we're not running ActiveRecord, return the workid.
    else
      workid
    end
  rescue => e
    "failed #{e}"
  end

  # Retrieve a specific work from Po.et, using the workId returned from
  # create_work.
  #
  # Usage example:
  # @blog_post.get_work
  #
  # Returns a hash with the created fields.
  def get_work
    frost_config = self.class.poet_frost_config 
    work_id_column = frost_config.work_id
    uri = PoetFrostConfig::FROST_URI + self[work_id_column].to_s
    req = Net::HTTP::Get.new(uri.path)
    req.content_type = 'application/json'
    # Use the referenced model field, if set.  Else use the string value, if it exists.  Else use
    # the environment variable.
    # TODO test, such as with a Blog model that belongs_to User, and has user.frost_key set in the config.
    req['token'] = if self.class.method_defined? frost_config[:api_key].to_s
      self.instance_eval(frost_config[:api_key])
    elsif frost_config[:api_key]
      frost_config[:api_key]
    else
      PoetFrostConfig::FROST_API_KEY
    end
    res = PoetFrostConfig::FROST_HTTP.request(req)
    res.body
  rescue => e
    "failed #{e}"
  end

  # Retrieve all works submitted by your Frost API Token.
  #
  # Usage example:
  # @user.get_all_works
  #
  # Returns an array of individual works (hashes)
  def get_all_works
    frost_config = self.class.poet_frost_config 
    req = Net::HTTP::Get.new(PoetFrostConfig::FROST_URI.path)
    req.content_type = 'application/json'
    # Use the referenced model field, if set.  Else use the string value, if it exists.  Else use
    # the environment variable.
    # TODO test, such as with a Blog model that belongs_to User, and has user.frost_key set in the config.
    req['token'] = if self.class.method_defined? frost_config[:api_key].to_s
                     self.instance_eval(frost_config[:api_key])
                   elsif frost_config[:api_key]
                     frost_config[:api_key]
                   else
                     PoetFrostConfig::FROST_API_KEY
                   end
    res = PoetFrostConfig::FROST_HTTP.request(req)
    res.body
  rescue => e
    "failed #{e}"
  end

end

