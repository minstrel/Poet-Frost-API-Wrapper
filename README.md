# Po.et Frost API Wrapper Gem for Ruby

## Setup

Register an API Token at https://frost.po.et/
Set it as the environment variable FROST\_TOKEN unless you plan to pass it in
directly to the methods (for instance, on a multi-user blog where each user
has their own API key).

## Methods

### Create Work

Posts a work to Po.et.  Returns a string with the workId that was created, or
any error messages.

```ruby
PoetFrostAPI.create_work(name: 'Work Name', # Required
                         datePublished: DateTime.now.iso8601,
                         dateCreated: DateTime.now.iso8601,
                         author: 'Author Name', # Required
                         tags: 'Tag1, Tag2',
                         content: 'Content body', # Required
                         api_key: 'API_key'
                         )
```

The date fields should be iso8601 formatted strings.  They will default to the
current date and time if omitted.

The tag field will default to an empty string if omitted.

The api\_key field will default to the environment variable FROST\_TOKEN if omitted.

For the time being, anything beyond these fields will be ignored.
Po.et's future plans are for the API to accept arbitrary metadata.

### Get a specific work by workId

Submit a workId (such as returned from create\_work) and return a hash of the
submitted work.

```ruby
PoetFrostAPI.get_work('workId', # Required
                      api_key: 'API_key')
```

The api\_key field will default to the environment variable FROST\_TOKEN if omitted.

### Get all works submitted by your API token

Submit a request and return an array of individual works (hashes).

```ruby
PoetFrostAPI.get_all_works(api_key: 'API_key')
```

The api\_key field will default to the environment variable FROST\_TOKEN if omitted.

## Rails-specific

For now, the easiest method to integrate this into Rails is to simply add the
gem to your Gemfile and, in the model that will contain the fields to submit,
add the following, where article\_name, created\_at, author, etc correspond
to the appropriate fields in your database model.

Yo dawg, I heard you like wrappers...

```ruby
class MyBlog < ApplicationRecord
  
  # Other stuff

  def post_to_poet
    PoetFrostAPI.create_work(name: article_name,
                             datePublished: created_at.iso8601, # Can omit
                             dateCreated: created_at.iso8601, # Can omit
                             author: author,
                             tags: tags, # Can omit
                             content: content,
                             api_key: frost_token # Omit if using FROST_TOKEN env variable
                             )
  end

end
```

Then when you want to post to Po.et from your controller, call (where @blog
is an instance of MyBlog):

```ruby
@blog.post_to_poet
```

If you will be using per-user API keys, I suggest encrypting the api key field
with [attr\_encrypted](https://github.com/attr-encrypted/attr_encrypted).

I'll see if the configuration can be made easier, although it will always 
involve telling each model which field to map to which API field, so I'm not
sure how much more concise it can get.
