require 'spec_helper'

module Sym
  module App
    RSpec.describe Sym::Application do

      context 'basic initialization' do
        let(:opts) { { generate: true } }
        let(:application) { Sym::Application.new(opts) }

        it 'should properly initialize' do
          expect(application).to_not be_nil
          expect(application.opts).to_not be_nil
          expect(application.opts[:generate]).to be_truthy
          expect(application.command).to be_a_kind_of(Sym::App::Commands::GenerateKey)
        end
      end

      context 'editor' do
        let(:opts) { { help: true } }
        let(:application) { Sym::Application.new(opts) }
        let(:existing_editor) { 'exe/sym' }
        let(:non_existing_editor) { '/tmp/broohaha/vim' }
        it 'should return the first valid editor from the list' do
          expect(application).to_not be_nil
          expect(application).to receive(:editors_to_try).
            and_return([non_existing_editor, existing_editor])
          expect(application.editor).to eql(existing_editor)
        end
      end

      context '#initialize_key_source' do
        include_examples :encryption

        RSpec.shared_examples 'a private key detection' do
          let(:key_data) { private_key }
          let(:opts) { { encrypt: true, string: 'hello', key: key_data } }
          subject(:application) { Sym::Application.new(opts) }

          it 'should not have the default key' do
            expect(Sym.default_key?).to be(false)
          end

          context 'key supplied as a string' do
            before { application.send(:initialize_key_source) }
            its(:key) { should eq(key) }
          end

          context 'key supplied as a file path' do
            let(:tempfile)  { Tempfile.new }
            let(:key_data) { tempfile.path }

            before do
              tempfile.write(private_key)
              tempfile.flush
              application.send(:initialize_key_source)
            end

            its(:key) { should eq(key) }

            it 'should have the key' do
              expect(File.read(tempfile.path)).to eq(private_key)
            end
          end
          
          context 'key supplied as environment variable' do
            let(:key_data) { 'PRIVATE_KEY' }
            before do
              allow(ENV).to receive(:[]).with('MEMCACHED_USERNAME')
              allow(ENV).to receive(:[]).with('SYM_CACHE_TTL')
              expect(ENV).to receive(:[]).with(key_data).and_return(private_key)
              application.send(:initialize_key_source)
            end
            its(:key) { should eq(key) }
          end

          context 'default key exists' do
            let(:key_data) { nil }

            before do
              expect(Sym).to receive(:default_key?).at_least(1).times.and_return(true)
              expect(Sym).to receive(:default_key).at_least(1).times.and_return(private_key)
              application.send(:initialize_key_source)
            end

            its(:key) { should eq(key) }
            its(:key_source) { should start_with('default_file://') }
          end
        end

        describe 'private key without a password' do
          it_behaves_like 'a private key detection' do
            let(:private_key) { key }
          end
        end

        describe 'private key with a password' do
          it_behaves_like 'a private key detection' do
            before do
              allow(application.input_handler).to receive(:ask).at_least(10).times.and_return(password)
              allow(ENV).to receive(:[]).with('SYM_PASSWORD').at_least(1).times.and_return(password)
            end
            let(:password) { 'pIA44z!w04DS' }
            let(:private_key) { test_instance.encr_password(key, password) }
          end
        end
      end
    end
  end
end
