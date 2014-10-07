require 'middleman-core'

module Middleman
  module CloudFront
    class Options < Struct.new(:access_key_id, :secret_access_key, :distribution_id, :filter, :after_build); end

    class << self
      def options
        @@cloudfront_options
      end

      def registered(app, options_hash = {}, &block)
        @@cloudfront_options = Options.new(options_hash)
        yield @@cloudfront_options if block_given?

        app.after_build do
          ::Middleman::Cli::CloudFront.new.invalidate(@@cloudfront_options) if @@cloudfront_options.after_build
        end

        app.send :include, Helpers
      end
      alias :included :registered
    end

    module Helpers
      def cloudfront_options
        ::Middleman::CloudFront.options
      end

      def invalidate(files = nil)
        ::Middleman::Cli::CloudFront.new.invalidate(cloudfront_options, files)
      end
    end

  end
end
