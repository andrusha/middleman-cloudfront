require 'middleman-core'

module Middleman
  module CloudFront
    class Options < Struct.new(:access_key_id, :secret_access_key, :distribution_id, :filter, :after_build); end

    class << self
      def options
        @@cloudfront_options
      end

      def registered(app, options_hash = {}, &block)
        options = Options.new options_hash
        yield options  if block_given?

        options.after_build ||= false
        options.filter      ||= /.*/

        app.after_build do
          ::Middleman::Cli::CloudFront.new.invalidate  if options.after_build
        end

        @@cloudfront_options = options
        app.send :include, Helpers
      end
      alias :included :registered
    end

    module Helpers
      def cloudfront_options
        ::Middleman::CloudFront.options
      end
    end

  end
end
