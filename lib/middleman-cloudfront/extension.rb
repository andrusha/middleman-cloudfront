require 'middleman-core'
require 'middleman-cloudfront/commands/invalidate'

module Middleman
  module CloudFront
    class Extension < Middleman::Extension
      # @param [Symbol] key The name of the option
      # @param [Object] default The default value for the option
      # @param [String] description A human-readable description of what the option does
      option :access_key_id, ENV['AWS_ACCESS_KEY_ID'], 'Access key id'
      option :secret_access_key, ENV['AWS_SECRET_ACCESS_KEY'], 'Secret access key'
      option :distribution_id, nil, 'Distribution id'
      option :filter, /.*/, 'Filter files to be invalidated'
      option :after_build, false, 'Invalidate after build'

      def initialize(app, options_hash={}, &block)
        super
      end

      def after_build
        Middleman::Cli::CloudFront::Invalidate.new.invalidate(options) if options.after_build
      end
      
      def after_configuration
        options.access_key_id ||= ENV['AWS_ACCESS_KEY_ID']
        options.secret_access_key ||= ENV['AWS_SECRET_ACCESS_KEY']
      end

      helpers do
        def invalidate(files = nil)
          Middleman::Cli::CloudFront::Invalidate.new.invalidate(options, files)
        end
      end
    end
  end
end
