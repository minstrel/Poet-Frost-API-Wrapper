require 'net/http'
require 'json'
require 'date'

# To use any of the methods, register an API key at https://frost.po.et/
# and save it as the environment variable FROST_TOKEN.
module PoetFrostAPI

  @@api_key = ENV['FROST_TOKEN']
  @@uri = URI('https://api.frost.po.et/works/')
  @@http = Net::HTTP.new(@@uri.host, @@uri.port)
  @@http.use_ssl = true

  # Register a work on Po.et.
  #
  # Usage: PoetFrostAPI.create_work(name: 'Work Name',
  #                                 datePublished: DateTime.now.iso8601,
  #                                 dateCreated: DateTime.now.iso8601,
  #                                 author: 'Author Name'
  #                                 tags: 'Tag1, Tag2'
  #                                 content: 'Content body'
  #                                 )
  #
  # Returns a string with the workid that was registered.
  def PoetFrostAPI.create_work(args = {})

    req = Net::HTTP::Post.new(@@uri.path)
    req.content_type = 'application/json'
    req['token'] = @@api_key
    req.body = { name: args[:name],
                 datePublished: args[:datePublished] || DateTime.now.iso8601,
                 dateCreated: args[:dateCreated] || DateTime.now.iso8601,
                 author: args[:author],
                 tags: args[:tags] || '',
                 content: args[:content]
    }.to_json
    res = @@http.request(req)
    JSON.parse(res.body)['workId']
  rescue => e
    puts "failed #{e}"
  end

  # Retrieve a specific work from Po.et, using the workId returned from
  # create_work.
  #
  # Usage: PoetFrostAPI.get_work(workId)
  #
  # Returns a hash with the created fields.
  def PoetFrostAPI.get_work(workId)
    uri = @@uri + workId
    req = Net::HTTP::Get.new(uri.path)
    req.content_type = 'application/json'
    req['token'] = @@api_key
    res = @@http.request(req)
    JSON.parse(res.body)
  rescue => e
    puts "failed #{e}"
  end

  # Retrieve all works submitted by your Frost API Token.
  #
  def PoetFrostAPI.get_all_works
    req = Net::HTTP::Get.new(@@uri.path)
    req.content_type = 'application/json'
    req['token'] = @@api_key
    res = @@http.request(req)
    JSON.parse(res.body)
  rescue => e
    puts "failed #{e}"
  end

end
