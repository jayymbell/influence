# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordValidator do
  # Create a test model to validate against
  let(:test_model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :password

      validates :password, password: true

      def self.name
        'TestModel'
      end
    end
  end

  let(:model) { test_model_class.new }

  describe 'validation rules' do
    context 'with valid password' do
      it 'passes validation when password has all required components' do
        model.password = 'Password123!@'
        expect(model).to be_valid
      end

      it 'passes with minimum 12 characters and all requirements' do
        model.password = 'Abc123!@defg'
        expect(model).to be_valid
      end
    end

    context 'when password is nil' do
      it 'skips validation and does not add errors' do
        model.password = nil
        expect(model).to be_valid
      end
    end

    context 'missing uppercase letter' do
      it 'adds error when password has no uppercase letters' do
        model.password = 'password123!@'
        expect(model).not_to be_valid
        expect(model.errors[:password]).to include('must contain at least one uppercase letter')
      end
    end

    context 'missing lowercase letter' do
      it 'adds error when password has no lowercase letters' do
        model.password = 'PASSWORD123!@'
        expect(model).not_to be_valid
        expect(model.errors[:password]).to include('must contain at least one lowercase letter')
      end
    end

    context 'missing digit' do
      it 'adds error when password has no digits' do
        model.password = 'Password!@#$'
        expect(model).not_to be_valid
        expect(model.errors[:password]).to include('must contain at least one number')
      end
    end

    context 'missing special character' do
      it 'adds error when password has no special characters' do
        model.password = 'Password123'
        expect(model).not_to be_valid
        expect(model.errors[:password]).to include('must contain at least one special character (@$!%*?&)')
      end

      it 'accepts any of the allowed special characters' do
        %w[@ $ ! % * ? &].each do |char|
          model.password = "Password123#{char}"
          expect(model).to be_valid, "Expected password with #{char} to be valid"
        end
      end
    end

    context 'multiple validation failures' do
      it 'adds multiple errors when password fails multiple rules' do
        model.password = 'weak'
        expect(model).not_to be_valid
        errors = model.errors[:password]
        expect(errors).to include('must contain at least one uppercase letter')
        expect(errors).to include('must contain at least one number')
        expect(errors).to include('must contain at least one special character (@$!%*?&)')
      end
    end
  end
end
