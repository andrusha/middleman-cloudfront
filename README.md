# Middleman CloudFront
A deploying tool for middleman which allows you to interact with Amazon CloudFront.
Some of its features are:  

* CloudFront cache invalidation;  
* Ability to call it from command line and after middleman build;  

# Usage

## Installation
Add this to `Gemfile`:  
```ruby
gem "middleman-cloudfront"
```

Then run:  
```
bundle install
```

## Configuration

Edit `config.rb` and add:  
```ruby
activate :cloudfront do |cf|
  cf.access_key_id = 'I'
  cf.secret_access_key = 'love'
  cf.distribution_id = 'cats'
  # cf.after_build = false
end
```

## Running

If you set `after_build` to `true` cache would be automatically invalidated after build:  
```bash
bundle exec middleman build
```

Otherwise you should run it through commandline interface like so:  
```bash
bundle exec middleman invalidate
```

# Notes
Inspired by [middleman-deploy](https://github.com/tvaughan/middleman-deploy) and [middleman-aws-deploy](https://github.com/coderoshi/middleman-aws-deploy).
