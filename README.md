# Omniauth Tesla

Tesla finally released OAuth2 support, and a slightly new API to replace the venerable, but unsafe Owner API. Now you can use this gem to authenticate users with their Tesla account, and be granted authorization to access the APIs.

This library does not implement any client libraries for the [Tesla Fleet API](https://developer.tesla.com/docs/fleet-api).

## Installation

```plain
bundle add omniauth-tesla
```

## Usage

### Scopes

You can specify the set of scopes for which your end users will grant you authorisation:

```ruby
use OmniAuth::Builder do
  provider :tesla, ENV["TESLA_CLIENT_ID"], ENV["TESLA_CLIENT_SECRET"],
    scope: "openid offline_access vehicle_device_data vehicle_cmds vehicle_charging_cmds"
end
```

[Authorization Scopes](https://developer.tesla.com/docs/fleet-api#authorization-scopes)

## Example app

To see it in action, there is a single file Rails app at [`examples/rails/config.ru`](./examples/rails/config.ru).

To run it:

```plain
export TESLA_CLIENT_ID=...
export TESLA_CLIENT_SECRET=...
( cd examples/rails; bundle exec rackup )
```

Then visit <http://localhost:9292>.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/drnic/omniauth-tesla>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/drnic/omniauth-tesla/blob/develop/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omniauth::Tesla project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/drnic/omniauth-tesla/blob/develop/CODE_OF_CONDUCT.md).
