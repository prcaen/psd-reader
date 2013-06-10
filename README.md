# Psd
This gem can parse a PSD file.

## Installation

Add this line to your application's Gemfile:

    gem 'psd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install psd

## Usage

### Parse PSD

```ruby
psd = Psd::Reader.new("file.psd")
psd.parse
```
