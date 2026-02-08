/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import Signup from '../../src/views/Signup.vue'

// Mock API
jest.mock('../../src/services/api', () => ({
  post: jest.fn()
}))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

const mockShowSnackbar = jest.fn()

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Signup.vue', () => {
  const createComponent = () => {
    return mount(Signup, {
      global: {
        mocks: {
          $router: mockRouter
        },
        provide: {
          showSnackbar: mockShowSnackbar,
          'Symbol(router)': mockRouter
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

  test('displays sign up title', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('Sign Up')
  })

  test('initializes with empty form fields', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.email).toBe('')
    expect(wrapper.vm.password).toBe('')
    expect(wrapper.vm.password_confirmation).toBe('')
  })

  test('updates email when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.email = 'newuser@example.com'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.email).toBe('newuser@example.com')
  })

  test('updates password when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.password = 'password123'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.password).toBe('password123')
  })

  test('updates password confirmation when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.password_confirmation = 'password123'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.password_confirmation).toBe('password123')
  })

  test('signs up successfully with valid data', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        message: 'Registration successful. Please check your email to confirm.'
      }
    })

    const wrapper = createComponent()
    wrapper.vm.email = 'newuser@example.com'
    wrapper.vm.password = 'password123'
    wrapper.vm.password_confirmation = 'password123'

    await wrapper.vm.handleSignup()

    expect(mockApi.post).toHaveBeenCalledWith('/signup', {
      user: {
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    })
    expect(mockShowSnackbar).toHaveBeenCalledWith(
      ['Registration successful. Please check your email to confirm.'],
      'success'
    )
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Login' })
  })

  test('handles signup API errors', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {
          errors: ['Email already exists', 'Password too weak']
        }
      }
    })

    const wrapper = createComponent()
    wrapper.vm.email = 'existing@example.com'
    wrapper.vm.password = 'weak'
    wrapper.vm.password_confirmation = 'weak'

    await wrapper.vm.handleSignup()

    expect(mockShowSnackbar).toHaveBeenCalledWith(
      ['Email already exists', 'Password too weak'],
      'error'
    )
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
    wrapper.vm.password = 'password123'
    wrapper.vm.password_confirmation = 'password123'

    await wrapper.vm.handleSignup()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['An unknown error occurred'], 'error')
  })

})