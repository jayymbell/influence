require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def success_action
      render_success(data: { foo: 'bar' }, message: 'All good', status: :ok)
    end

    def error_action
      render_error(errors: 'bad', message: 'Broken', status: :unprocessable_content)
    end

    def forbidden_action
      raise Pundit::NotAuthorizedError, 'not allowed'
    end
  end

  before do
    routes.draw do
      get 'success_action' => 'anonymous#success_action'
      get 'error_action' => 'anonymous#error_action'
      get 'forbidden_action' => 'anonymous#forbidden_action'
    end
  end

  describe '#render_success' do
    it 'returns standardized JSON with merged data' do
      process :success_action, method: :get

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['status']).to eq(200)
      expect(body['message']).to eq('All good')
      expect(body['foo']).to eq('bar')
    end
  end

  describe '#render_error' do
    it 'returns errors as an array and proper status' do
      process :error_action, method: :get

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['status']).to eq(422)
      expect(body['message']).to eq('Broken')
      expect(body['errors']).to eq(['bad'])
    end
  end

  describe 'Pundit rescue' do
    it 'returns forbidden JSON when Pundit::NotAuthorizedError is raised' do
      process :forbidden_action, method: :get

      expect(response).to have_http_status(:forbidden)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('You do not have permission to access this')
    end
  end
end
