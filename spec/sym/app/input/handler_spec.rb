# frozen_string_literal: true

require 'spec_helper'
require 'singleton'

module Sym
  module App
    RSpec.describe Input::Handler do
      def setup_handler(calls = [])
        calls.each do |hash|
          expect(handler).to receive(:prompt).with(hash[:message], hash[:color]).and_return(hash[:password])
        end
      end

      let(:password) { 'boobooboo' }
      let(:opts) { { password: true } }
      let(:handler) { Input::Handler.new }

      context 'entering password' do
        it 'should save what the stupid user entered' do
          setup_handler [{ message: 'Password: ', color: :green, password: password }]
          expect { handler.ask }.to_not raise_error
        end
        it 'should be what the stupid user entered' do
          setup_handler [{ message: 'Password: ', color: :green, password: password }]
          expect(handler.ask).to eql(password)
        end
      end

      context 'creating new password' do
        context 'passwords dont match' do
          it 'should raise an exception' do
            setup_handler [{ message: 'New Password     :  ', color: :blue, password: 'right password' },
                           { message: 'Confirm Password :  ', color: :blue, password: 'WhatsUpYo' }]
            expect { handler.new_password }.to raise_error(Sym::Errors::PasswordsDontMatch)
          end
        end

        context 'password is too short' do
          it 'should raise an exception' do
            setup_handler [
              { message: 'New Password     :  ', color: :blue, password: 'short' },
            ]
            expect { handler.new_password }.to raise_error(Sym::Errors::PasswordTooShort)
          end
        end
        context 'passwords match and are long enough' do
          it 'should raise an exception' do
            setup_handler [
              { message: 'New Password     :  ', color: :blue, password: 'WhatsUpYo' },
              { message: 'Confirm Password :  ', color: :blue, password: 'WhatsUpYo' }
            ]
            password = nil
            expect { password = handler.new_password }.not_to raise_error
            expect(password).to eql('WhatsUpYo')
          end
        end
      end
    end
  end
end
