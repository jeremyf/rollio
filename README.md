# Rollio

A tool for loading random tables, rolling on those tables, and rendering the output.

## Todo List

- [ ] Create schema to define valid JSON document
- [ ] Integrate schema validation for loaded JSON document
- [ ] Create structure for loading tables
- [ ] Create command line tool
  - [ ] List available tables (with help) (e.g. `rollio roll -h`)
  - [ ] Look to parameterization of table rolls
  - [ ] Roll on tables (e.g. `rollio roll background`)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rollio'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install rollio
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jeremyf/rollio. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Rollio project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jeremyf/rollio/blob/master/CODE_OF_CONDUCT.md).
