require 'spec_helper'

require 'fog/aws/models/cdn/distributions'

describe Middleman::Cli::CloudFront do
  let(:cloudfront) do
    described_class.new.tap do |cloudfront|
      cloudfront.stub(:options).and_return Middleman::CloudFront::Options.new(
        'access_key_id_123',
        'secret_access_key_123',
        'distribution_id_123',
        'filter_123',
        'after_build_123'
      );
    end
  end

  let(:distribution) { double('distribution', invalidations: double('invalidations')) }

  describe '#invalidate' do
    before do
      Fog::CDN::AWS::Distributions.any_instance.stub(:get).and_return(distribution)
      distribution.invalidations.stub(:create) do
        double('invalidation', status: 'InProgress', wait_for: ->{} )
      end
    end

    it 'gets the correct distribution' do
      cloudfront.stub(:list_files).and_return []
      expect_any_instance_of(Fog::CDN::AWS::Distributions).to receive(:get).with('distribution_id_123')
      cloudfront.invalidate
    end

    context 'when the amount of files to invalidate is under the limit' do
      it 'divides them up in packages and creates one invalidation per package' do
        files = (1..Middleman::Cli::CloudFront::INVALIDATION_LIMIT).map do |i|
          "file_#{i}"
        end
        cloudfront.stub(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files)
        cloudfront.invalidate
      end
    end

    context 'when the amount of files to invalidate is over the limit' do
      it 'creates only one invalidation with all of them' do
        files = (1..(Middleman::Cli::CloudFront::INVALIDATION_LIMIT * 3)).map do |i|
          "file_#{i}"
        end
        cloudfront.stub(:list_files).and_return files
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[0, Middleman::Cli::CloudFront::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CloudFront::INVALIDATION_LIMIT, Middleman::Cli::CloudFront::INVALIDATION_LIMIT])
        expect(distribution.invalidations).to receive(:create).once.with(paths: files[Middleman::Cli::CloudFront::INVALIDATION_LIMIT * 2, Middleman::Cli::CloudFront::INVALIDATION_LIMIT])
        cloudfront.invalidate
      end
    end
  end
end
