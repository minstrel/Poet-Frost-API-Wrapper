require 'net/http'
require 'json'
require 'date'

# To use any of the methods, register an API key at https://frost.po.et/
# and save it as the environment variable FROST_TOKEN.
# For the current easiest way to integrate to Rails, see the github readme
# here: https://github.com/minstrel/Poet-Frost-API-Wrapper
module PoetFrostAPI

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

end

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

module PoetFrostAPI

  # Post the work to Po.et
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
    # Set the token field to the api_key field if it exists, then delete it so it doesn't get passed on.
    req['token'] = args[:api_key] || PoetFrostConfig::FROST_API_KEY
    args.delete(:api_key) if args[:api_key]
    args[:datePublished] ||= DateTime.now.iso8601
    args[:dateCreated] ||= DateTime.now.iso8601
    args[:tags] ||= ''
    req.body = args.to_json
    res = PoetFrostConfig::FROST_HTTP.request(req)
    # TODO if the model has a workId field defined, save the workId in that field
    JSON.parse(res.body)['workId']
  rescue => e
    "failed #{e}"
  end

  # TODO get_work
  #
  #def PoetFrostAPI.get_work(workId, args = {})
  #  uri = @@uri + workId
  #  req = Net::HTTP::Get.new(uri.path)
  #  req.content_type = 'application/json'
  #  args.keep_if { |k, v| [:api_key].include?(k) }
  #  req['token'] = args[:api_key] || @@api_key
  #  res = @@http.request(req)
  #  JSON.parse(res.body)
  #rescue => e
  #  "failed #{e}"
  #end
  # TODO get_all_works
  #
  #def PoetFrostAPI.get_all_works(args = {})
  #  req = Net::HTTP::Get.new(@@uri.path)
  #  req.content_type = 'application/json'
  #  args.keep_if { |k, v| [:api_key].include?(k) }
  #  req['token'] = args[:api_key] || @@api_key
  #  res = @@http.request(req)
  #  JSON.parse(res.body)
  #rescue => e
  #  "failed #{e}"
  #end
end
