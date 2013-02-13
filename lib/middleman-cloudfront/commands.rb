require "middleman-core/cli"
require "middleman-cloudfront/extension"
require "fog"

module Middleman
  module Cli

    class CloudFront < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :invalidate

      def self.exit_on_failure?
        true
      end

      desc "cloudfront:invalidate", "A way to deal with your ClodFront distributions"
      def invalidate
        puts "## Invalidating files on CloudFront"
        cdn = Fog::CDN.new({
          :provider               => 'AWS',
          :aws_access_key_id      => options.access_key_id,
          :aws_secret_access_key  => options.secret_access_key
        })

        distribution = cdn.distributions.get options.distribution_id

        # CloudFront limits amount of files which can be invalidated by one request
        list_files.each_slice(1000) do |slice|
          puts "Please wait while Cloudfront is reloading #{slice.length} paths, it might take up to 10 minutes"
          invalidation = distribution.invalidations.create :paths => slice
          invalidation.wait_for { ready? }
        end
      end

      protected

      def options
        ::Middleman::Application.server.inst.options
      rescue
        raise Error, <<-EOF.lines.map(&:strip).join("\n")
          ERROR: You need to activate the cloudfront extension in config.rb.

          The example configuration is:
          activate :cloudfront do |cf|
            cf.access_key_id = 'I'
            cf.secret_access_key = 'love'
            cf.distribution_id = 'cats'
            cf.after_build = true  # default is false
          end
        EOF
      end

      def list_files
        Dir.chdir('build/') do
          files = Dir.glob('**/*', File::FNM_DOTMATCH).reject { |f| File.directory? f }
          # if :directory_indexes is active, we must invalidate both files and dirs
          files += files.map{|f| f.gsub(/\/index\.html$/, '/') }
          files.uniq!.map! { |f| f.start_with?('/') ? f : "/#{f}" }
        end
      end

    end

    Base.map({"inv" => "cloudfront:invalidate"})
  end
end
