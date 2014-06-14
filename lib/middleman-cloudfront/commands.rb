require "middleman-core/cli"
require "middleman-cloudfront/extension"
require "fog"

module Middleman
  module Cli

    class CloudFront < Thor
      include Thor::Actions

      INVALIDATION_LIMIT = 1000

      check_unknown_options!

      namespace :invalidate

      def self.exit_on_failure?
        true
      end

      desc "cloudfront:invalidate", "A way to deal with your ClodFront distributions"
      def invalidate(options)
        [:access_key_id, :secret_access_key, :distribution_id, :filter].each do |key|
          raise StandardError, "Configuration key #{key} is missing." if options.public_send(key).nil?
        end

        puts "## Invalidating files on CloudFront"
        cdn = Fog::CDN.new({
          :provider               => 'AWS',
          :aws_access_key_id      => options.access_key_id,
          :aws_secret_access_key  => options.secret_access_key
        })

        distribution = cdn.distributions.get(options.distribution_id)

        # CloudFront limits the amount of files which can be invalidated by one request to 1000.
        # If there are more than 1000 files to invalidate, do so sequentially and wait until each validation is ready.
        # If there are max 1000 files, create the invalidation and return immediately.
        files = list_files(options.filter)
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

      def list_files(filter)
        Dir.chdir('build/') do
          Dir.glob('**/*', File::FNM_DOTMATCH).tap do |files|
            # Remove directories
            files.reject! { |f| File.directory?(f) }

            # Remove files that do not match filter
            files.reject! { |f| f !~ filter }

            # Add directories of index.html files since they have to be
            # invalidated as well if :directory_indexes is active
            files.each do |file|
              file_dir = file.sub(/\bindex\.html\z/, '')
              files << file_dir if file_dir != file
            end

            # Add leading slash
            files.map! { |f| f.start_with?('/') ? f : "/#{f}" }
          end
        end
      end

    end

    Base.map({"inv" => "invalidate"})
  end
end
