/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import PasswordReset from '../../src/views/PasswordReset.vue'

// Mock API
jest.mock('../../src/services/api', () => ({
  post: jest.fn()
}))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

const mockRoute = {
  query: {}
}

// Mock vue-router composables
jest.mock('vue-router', () => ({
  useRouter: () => mockRouter,
  useRoute: () => mockRoute
}))

const mockShowSnackbar = jest.fn()

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('PasswordReset.vue', () => {
  const createComponent = () => {
    return mount(PasswordReset, {
      global: {
        provide: {
          showSnackbar: mockShowSnackbar,
        },
        stubs: {
          VContainer: true,
          VForm: true,
          VTextField: true,
          VBtn: true,
          VRow: true,
          VCol: true
        }
      }
    })
  }

  test('component mounts successfully', () => {
    const wrapper = createComponent()
    expect(wrapper.exists()).toBe(true)
  })

  test('displays reset password title', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('Reset Password')
  })

  test('initializes with empty email field', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.email).toBe('')
  })

  test('updates email when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.email = 'user@example.com'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.email).toBe('user@example.com')
  })

  test('shows error when email field is empty', async () => {
    const wrapper = createComponent()
    await wrapper.vm.requestPasswordReset()
    
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Please enter your email address.'], 'error')
    expect(mockApi.post).not.toHaveBeenCalled()
  })

  test('requests password reset successfully with valid email', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        status: {
          message: 'Password reset email sent'
        }
      }
    })

    const wrapper = createComponent()
    wrapper.vm.email = 'user@example.com'

    await wrapper.vm.requestPasswordReset()

    expect(mockApi.post).toHaveBeenCalledWith('/password', {
      user: { email: 'user@example.com' }
    })
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Password reset email sent'], 'success')
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Login' })
  })

  test('handles password reset request API errors', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {
          errors: ['Email not found']
        }
      }
    })

    const wrapper = createComponent()
    wrapper.vm.email = 'nonexistent@example.com'

    await wrapper.vm.requestPasswordReset()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Email not found'], 'error')
    expect(mockRouter.push).not.toHaveBeenCalled()
  })

  test('handles API errors without specific error messages', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {}
      }
    })

    const wrapper = createComponent()
    wrapper.vm.email = 'user@example.com'

    await wrapper.vm.requestPasswordReset()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['An unknown error occurred'], 'error')
  })

  test('validates email is not empty before API call', async () => {
    const wrapper = createComponent()
    wrapper.vm.email = ''  // actual empty string

    await wrapper.vm.requestPasswordReset()

    expect(mockApi.post).not.toHaveBeenCalled()
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Please enter your email address.'], 'error')
  })
})