/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import Confirmation from '../../src/views/Confirmation.vue'

// Mock API
jest.mock('../../src/services/api', () => ({
  get: jest.fn()
}))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

const mockRoute = {
  query: {
    confirmation_token: 'test-token-123'
  }
}

const mockShowSnackbar = jest.fn()

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Confirmation.vue', () => {
  const createComponent = () => {
    return mount(Confirmation, {
      global: {
        mocks: {
          $router: mockRouter,
          $route: mockRoute
        },
        provide: {
          showSnackbar: mockShowSnackbar,
          'Symbol(router)': mockRouter,
          'Symbol(route location)': mockRoute
        },
        stubs: {
          VContainer: true,
          VBtn: true
        }
      }
    })
  }

  test('component mounts successfully', () => {
    const wrapper = createComponent()
    expect(wrapper.exists()).toBe(true)
  })

  test('displays confirm email button', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('Confirm Email')
  })

  test('confirms user successfully with valid token', async () => {
    mockApi.get.mockResolvedValue({
      data: {
        status: { message: 'Email confirmed successfully' }
      }
    })

    const wrapper = createComponent()
    await wrapper.vm.confirmUser()

    expect(mockApi.get).toHaveBeenCalledWith('/confirmation', {
      params: { confirmation_token: 'test-token-123' }
    })
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Email confirmed successfully'], 'success')
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Login' })
  })

  test('handles invalid token error (406)', async () => {
    mockApi.get.mockRejectedValue({
      response: {
        data: {
          status: 406
        }
      }
    })

    const wrapper = createComponent()
    await wrapper.vm.confirmUser()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Invalid token.'], 'error')
  })

  test('handles general errors with error field', async () => {
    mockApi.get.mockRejectedValue({
      response: {
        data: {
          status: 500,
          error: 'Server error'
        }
      }
    })

    const wrapper = createComponent()
    await wrapper.vm.confirmUser()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Server error'], 'error')
  })

  test('handles errors array', async () => {
    mockApi.get.mockRejectedValue({
      response: {
        data: {
          status: 422,
          errors: ['Error 1', 'Error 2']
        }
      }
    })

    const wrapper = createComponent()
    await wrapper.vm.confirmUser()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Error 1', 'Error 2'], 'error')
  })
})