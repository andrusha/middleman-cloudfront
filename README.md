# Middleman CloudFront [![Build Status](https://travis-ci.org/andrusha/middleman-cloudfront.svg?branch=master)](https://travis-ci.org/andrusha/middleman-cloudfront) [![Dependency Status](https://gemnasium.com/andrusha/middleman-cloudfront.png)](https://gemnasium.com/andrusha/middleman-cloudfront) [![Code Climate](https://codeclimate.com/github/andrusha/middleman-cloudfront.png)](https://codeclimate.com/github/andrusha/middleman-cloudfront)
A deploying tool for middleman which allows you to interact with Amazon CloudFront.
Some of its features are:  

* CloudFront cache invalidation;  
* Ability to call it from command line and after middleman build;  
* Ability to filter files which are going to be invalidated by regex;  

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
  # cf.filter = /\.html$/i  # default is /.*/
  # cf.after_build = false  # default is false
end
```

On Amazon use following parameters inside your IAM policy:
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1409254980000",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetDistribution"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
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

or from within Middleman, optionally specifying a list of files to invalidate:

```ruby
# Invalidate automatic selection of files from build directory
invalidate

# Invalidate explicit list of files
invalidate %w(/index.html /images/example.png)
```

## S3 + Cloudfront deploying

In real world this gem shouldn't be used alone, but as a part of your 
deployment solution. As for me I use it with [middleman-sync](https://github.com/karlfreeman/middleman-sync) and my configuration file looks like this:

```ruby
configure :build do
  # so there would be no need in invalidationg css-js files on cdn
  activate :asset_hash
end

activate :sync do |sync|
  sync.fog_provider = 'AWS'
  sync.fog_directory = '...'
  sync.fog_region = 'us-west-1'
  sync.aws_access_key_id = ENV['AWS_ACCESS_KEY']
  sync.aws_secret_access_key = ENV['AWS_SECRET']
  sync.existing_remote_files = 'delete'
  sync.gzip_compression = true
end

activate :cloudfront do |cf|
  cf.access_key_id = ENV['AWS_ACCESS_KEY']
  cf.secret_access_key = ENV['AWS_SECRET']
  cf.distribution_id = '...'
  cf.filter = /\.html$/i
end
```

And when I want to deploy my site I do:
```bash
AWS_ACCESS_KEY= AWS_SECRET= bundle exec middleman sync
AWS_ACCESS_KEY= AWS_SECRET= bundle exec middleman invalidate
```

If you use [middleman-s3_sync](https://github.com/fredjean/middleman-s3_sync) for deployment, you can use its `after_s3_sync` hook to automatically invalidate updated files after syncing:
```ruby
after_s3_sync do |files_by_status|
  invalidate files_by_status[:updated]
end
```

NOTE: The `after_s3_sync` hook only works with middleman-s3_sync v3.x and below. It has been [removed in v4.0](https://github.com/fredjean/middleman-s3_sync/blob/master/Changelog.md#v400).
