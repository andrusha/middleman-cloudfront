require 'middleman-core'
require 'middleman-cloudfront/commands/invalidate'

module Middleman
  module CloudFront
    class Extension < Middleman::Extension
      # @param [Symbol] key The name of the option
      # @param [Object] default The default value for the option
      # @param [String] description A human-readable description of what the option does
      option :access_key_id, nil, 'Access key id'
      option :secret_access_key, nil, 'Secret access key'
      option :distribution_id, nil, 'Distribution id'
      option :filter, /.*/, 'Filter files to be invalidated'
      option :after_build, false, 'Invalidate after build'

      def initialize(app, options_hash={}, &block)
        super
      end

      def after_build
        Middleman::Cli::CloudFront::Invalidate.new.invalidate(options) if options.after_build
      end

      helpers do
        def invalidate(files = nil)
          Middleman::Cli::CloudFront::Invalidate.new.invalidate(options, files)
        end
      end
    end
  end
end
