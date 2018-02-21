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
