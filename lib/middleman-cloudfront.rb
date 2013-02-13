require 'middleman-core'
require 'middleman-cloudfront/commands'

::Middleman::Extensions.register(:cloudfront, ">= 3.0.0") do
  require "middleman-cloudfront/extension"
  ::Middleman::CloudFront
end
