require 'middleman-cli'
require 'middleman-cloudfront/extension'
require 'fog/aws'

module Middleman
  module Cli
    module CloudFront
      # This class provides an "invalidate" command for the middleman CLI.
      class Invalidate < ::Thor::Group
        include Thor::Actions

        INVALIDATION_LIMIT = 1000
        INDEX_REGEX = /
          \A
            (.*\/)?
            index\.html
          \z
        /ix

        check_unknown_options!

        def self.exit_on_failure?
          true
        end

        def invalidate(options = nil, files = nil)

          # If called via commandline, discover config (from bin/middleman)
          if options.nil?
            app = Middleman::Application.new do
              config[:mode] = :config
              config[:exit_before_ready] = true
              config[:watcher_disable] = true
              config[:disable_sitemap] = true
            end

            # Get the options from the cloudfront extension
            extension = app.extensions[:cloudfront]
            unless extension.nil?
              options = extension.options
            end
          end

          if options.nil?
            configuration_usage
          end

          [:distribution_id, :filter].each do |key|
            raise StandardError, "Configuration key #{key} is missing." if options.public_send(key).nil?
          end

          puts '## Invalidating files on CloudFront'

          fog_options = {
            :provider => 'AWS'
          }

          fog_options.merge!(
            if options.access_key_id && options.secret_access_key
              {
                :aws_access_key_id     => options.access_key_id,
                :aws_secret_access_key => options.secret_access_key
              }
            else
              { :use_iam_profile => true }
            end
          )

          cdn = Fog::CDN.new(fog_options)

          distribution = cdn.distributions.get(options.distribution_id)

          raise StandardError, "Cannot access Distribution with id #{options.distribution_id}." if distribution.nil?


          # CloudFront limits the amount of files which can be invalidated by one request to 1000.
          # If there are more than 1000 files to invalidate, do so sequentially and wait until each validation is ready.
          # If there are max 1000 files, create the invalidation and return immediately.
          files = normalize_files(files || list_files(options.filter))
          return if files.empty?

          if files.count <= INVALIDATION_LIMIT
            puts "Invalidating #{files.count} files. It might take 10 to 15 minutes until all files are invalidated."
            puts 'Please check the AWS Management Console to see the status of the invalidation.'
            invalidation = distribution.invalidations.create(:paths => files)
            raise StandardError, %(Invalidation status is #{invalidation.status}. Expected "InProgress") unless invalidation.status == 'InProgress'
          else
            slices = files.each_slice(INVALIDATION_LIMIT)
            puts "Invalidating #{files.count} files in #{slices.count} batch(es). It might take 10 to 15 minutes per batch until all files are invalidated."
            slices.each_with_index do |slice, i|
              puts "Invalidating batch #{i + 1}..."
              invalidation = distribution.invalidations.create(:paths => slice)
              invalidation.wait_for { ready? } unless i == slices.count - 1
            end
          end
        end

        protected

        def configuration_usage
          raise Error, <<-TEXT
ERROR: You need to activate the cloudfront extension in config.rb.

The example configuration is:
activate :cloudfront do |cf|
  cf.access_key_id     = 'I'
  cf.secret_access_key = 'love'
  cf.distribution_id   = 'cats'
  # cf.filter            = /\.html/i  # default /.*/
  # cf.after_build       = true  # default is false
end
          TEXT
        end

        def list_files(filter)
          Dir.chdir('build/') do
            Dir.glob('**/*', File::FNM_DOTMATCH).tap do |files|
              # Remove directories
              files.reject! { |f| File.directory?(f) }

              # Remove files that do not match filter
              files.reject! { |f| f !~ filter }
            end
          end
        end

        def normalize_files(files)
          # Add directories since they have to be invalidated
          # as well if :directory_indexes is active
          files += files.grep(INDEX_REGEX).map do |file|
            file == 'index.html' ? '/' : File.dirname(file) << '/'
          end.uniq

          # URI encode and add leading slash
          files.map { |f| URI::encode(f.start_with?('/') ? f : "/#{f}") }
        end

        # Add to CLI
        Base.register(self, 'invalidate', 'invalidate', 'Invalidate a cloudfront distribution.')

        # Map "inv" to "invalidate"
        Base.map('inv' => 'invalidate')
      end
    end
  end
end
