# require 'spec_helper'
#
# describe Travis::Build::Script::Addons::Artifacts::Validator do
#   let(:data)   { Travis::Build::Data.new(PAYLOADS[:push].deep_clone) }
#   let(:config) { { key: 'key', secret: 'secret', bucket: 'bucket', branch: ['master'] } }
#   subject      { described_class.new(data, config).tap { |subject| subject.valid? } }
#
#   it 'returns true if all is cool' do
#     expect(subject).to be_valid
#   end
#
#   describe 'S3 configuration' do
#     [:key, :secret, :bucket].each do |key|
#       describe "if the key #{key.inspect} is missing" do
#         it "returns false" do
#           config.delete(key)
#           expect(subject.valid?).to eql(false)
#         end
#
#         it "adds an error message about the missing key" do
#           config.delete(key)
#           expect(subject.errors).to eql([described_class::MSGS[:config_missing] % key.inspect])
#         end
#       end
#     end
#
#     it "adds an error message about several missing keys" do
#       config.delete(:key)
#       config.delete(:secret)
#       expect(subject.errors).to eql([described_class::MSGS[:config_missing] % ':key, :secret'])
#     end
#   end
#
#   describe 'request type' do
#     it 'returns false for a pull request' do
#       data.stubs(:pull_request).returns '123'
#       expect(subject).not_to be_valid
#     end
#
#     it 'adds an error message about pull requests being rejected' do
#       data.stubs(:pull_request).returns '123'
#       expect(subject.errors).to eql([described_class::MSGS[:pull_request]])
#     end
#   end
#
#   describe 'branch configuration' do
#     it 'returns true if there are no branches configured' do
#       config.delete(:branch)
#       expect(subject).to be_valid
#     end
#
#     it 'returns true if the configured branches equals the actual branch' do
#       config[:branch] = 'master'
#       expect(subject).to be_valid
#     end
#
#     it 'returns true if the configured branches include the actual branch' do
#       config[:branch] = ['master']
#       expect(subject).to be_valid
#     end
#
#     it 'returns false if the configured branches do not include the actual branch' do
#       config[:branch] = ['development']
#       expect(subject).not_to be_valid
#     end
#
#     it 'adds an error message about the branch being disabled' do
#       config[:branch] = ['development']
#       expect(subject.errors).to eql([described_class::MSGS[:branch_disabled] % 'master'])
#     end
#   end
# end
