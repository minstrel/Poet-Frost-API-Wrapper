# Po.et Frost API Wrapper Gem for Ruby

## Setup

Register an API Token at https://frost.po.et/
Set it as the environment variable FROST\_TOKEN unless you plan to pass it in
directly to the methods (for instance, on a multi-user blog where each user
has their own API key).

## Including poet\_frost\_API in ActiveRecord/Rails (or other classes)

I'll be describing how to include this gem into Rails, but the steps can
be generalized to include it in any Ruby class with the proper attributes.

In your model, include PoetFrostAPI:

```ruby
class MyModel < ApplicationRecord
  include PoetFrostAPI
end
```

Map the fields accepted by the API to the attributes in your model as follows.
Note: in the future, the API is expected to accept arbritrary fields, but
for now only the ones below are valid and the gem will filter out any others.

```ruby
class MyModel < ApplicationRecord
  poet_frost_configure do |config|
    config.name = :name # Required
    config.datePublished = :updated_at
    config.dateCreated = :created_at
    config.author = :author # Required
    config.tags = :tags
    config.content = :body # Required
    config.work_id = :workid
    config.api_key = :frost_api_key
  end
end
```

The left side of the = statement is the API field.
The right side of the = statement is the attribute of your model it maps to.
So "config.content = :body" maps the body attribute of your model to Po.et's
content field.

The only fields you are required to configure are name, author and content.
All others can either be omitted or will use sensible defaults.

The date fields should either be iso8601 formatted strings, or respond to the
method #iso8601 (updated\_at and created\_at in ActiveRecord do this).

The api\_key field will default to the environment variable FROST\_TOKEN if omitted.
If you will be using per-user API keys, I suggest encrypting the api key field
with [attr\_encrypted](https://github.com/attr-encrypted/attr_encrypted).

## Methods

### Create Work

Posts a work to Po.et.  Returns a string with the workId that was created, or
any error messages.

```ruby
@my_model_instance.post_to_poet
```

If the object is an ActiveRecord object and has a mapped work\_id field, it
will automatically be updated with the returned work\_id.

### Get a specific work by workId

Call on an object with a field mapped to work\_id and return a hash of the submitted
work.

```ruby
@my_model_instance.get_work
```

### Get all works submitted by your API token

Call on an object with a field mapped to api\_key and return an array of all
works submitted by that api key.

```ruby
@my_model_instance.get_all_works
```

## Class Methods

If you're not integrating poet\_frost\_API via include, you can call these
class methods directly.

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


## Old Rails integration method

This method to integrate with Rails is deprecated, but I'm including it here
because it was the original method before better Rails integration was
introduced.  I don't think anyone is using it, but I'm including it here
for reference for the time being.

Yo dawg, I heard you like wrappers...

```ruby
class MyBlog < ApplicationRecord
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

