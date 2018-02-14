# Po.et Frost API Wrapper Gem for Ruby

## Setup

Register an API Token at https://frost.po.et/ and set it as the environment
variable FROST\_TOKEN

## Methods

### Create Work

Posts a work to Po.et.  Returns a string with the workId that was created, or
any error messages.

```ruby
PoetFrostAPI.create_work(name: 'Work Name',
                         datePublished: DateTime.now.iso8601,
                         dateCreated: DateTime.now.iso8601,
                         author: 'Author Name',
                         tags: 'Tag1, Tag2',
                         content: 'Content body'
                         )
```

Both date fields and the tag field can be omitted.

The date fields should be iso8601 formatted strings.  They will default to the
current date and time if left blank.

The tag field will default to an empty string if left blank.

For the time being, anything beyond these fields will be ignored.  Future plans are for the API to accept arbitrary metadata.

### Get a specific work by workId

Submit a workId (such as returned from create\_work) and return a hash of the
submitted work.

```ruby
PoetFrostAPI.get_work('workId')
```

### Get all works submitted by your API token

Submit a request and return an array of individual works (hashes).

```ruby
PoetFrostAPI.get_all_works
```

## Rails-specific

For now, the easiest method to integrate this into Rails is to simply add the
gem to your Gemfile and, in the model that will contain the fields to submit,
do the following, where article\_name, created\_at, author, etc correspond
to the appropriate fields in your database model.

Yo dawg, I heard you like wrappers...

```ruby
class MyBlog < ApplicationRecord
  
  # Other stuff

  def post_to_poet
    PoetFrostAPI.create_work(name: article_name,
                             datePublished: created_at.iso8601,
                             dateCreated: created_at.iso8601,
                             author: author,
                             tags: tags,
                             content: content
                             )
  end

end
```

Then when you want to post to Po.et from your controller, call (where @blog
is an instance of MyBlog):

```ruby
@blog.post_to_poet
```

I'm working on securely integrating the API token into the database model, so
Rails users can either use the environment variable, for instance in a single
user blog, or use a database field in a multiuser Rails app.

After that, I'll see if the configuration can be made easier, although it
will always involve telling each model which field to map to which API field,
so I'm not sure how much more concise it can get.
