require 'pathname' # for some reason, had to require this because middleman-core 4.1.7 did not.
require 'middleman-cloudfront/extension'

Middleman::Extensions.register :cloudfront, Middleman::CloudFront::Extension
