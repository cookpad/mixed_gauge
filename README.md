# MixedGauge

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/mixed_gauge`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mixed_gauge'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mixed_gauge

## Usage

```yaml
# database.yml
production_user_alpha:
  adapter: mysql2
  username: user_writable
  host: db-user-001
production_user_beta:
  adapter: mysql2
  username: blog_writable
  host: db-user-002
```

```ruby
MixedGauge.configure do |config|
  config.define_cluster(:user) do |cluster|
    cluster.define_slots(1..1024)
    cluster.add(1..512, :production_user_alpha)
    cluster.add(513..1024, :production_user_beta)
  end
end
```

```ruby
class User < ActiveRecord::Base
  self.abstruct_class = true
  include MixedGauge::Model
  hash_key :email
end

user = User.get('alice@example.com')
user.name = 'new alice'
user.save!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/mixed_gauge/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
