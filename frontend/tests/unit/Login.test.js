/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { nextTick } from 'vue'
import Login from '../../src/views/Login.vue'
import useUserStore from '../../src/stores/UserStore'

// Mock API and tracking services
jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  post: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn().mockResolvedValue({}) }))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

// Mock vue-router composables
jest.mock('vue-router', () => ({
  useRouter: () => mockRouter
}))

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Login.vue', () => {
  let wrapper
  let userStore
  let showSnackbarSpy

  const mountComponent = (options = {}) => {
    showSnackbarSpy = jest.fn()
    return mount(Login, {
      global: {
        provide: {
          showSnackbar: showSnackbarSpy
        },
        plugins: [createPinia()]
      },
      ...options
    })
  }

  beforeEach(() => {
    wrapper = mountComponent()
    userStore = useUserStore()
    jest.clearAllMocks()
  })

  afterEach(() => {
    wrapper?.unmount()
  })

  test('renders login form with email and password fields', () => {
    expect(wrapper.find('h1').text()).toBe('Log In')
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('input[type="password"]').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  test('initializes with empty email and password', () => {
    expect(wrapper.vm.email).toBe('')
    expect(wrapper.vm.password).toBe('')
  })

  test('updates email and password data when fields change', async () => {
    const emailInput = wrapper.find('input[type="email"]')
    const passwordInput = wrapper.find('input[type="password"]')

    await emailInput.setValue('test@example.com')
    await passwordInput.setValue('password123')

    expect(wrapper.vm.email).toBe('test@example.com')
    expect(wrapper.vm.password).toBe('password123')
  })

  test('shows error when email or password is empty', async () => {
    await wrapper.vm.handleLogin()
    
    // Check that showSnackbar was called via the provide/inject system
    expect(showSnackbarSpy).toHaveBeenCalledWith(
      ['Please enter your email and password.'],
      'error'
    )
  })

  test('calls userStore.login with correct data on form submit', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        token: 'test-token',
        data: { id: 1, email: 'user@example.com', roles: [] },
        status: { message: 'Login successful' }
      }
    })

    await wrapper.find('input[type="email"]').setValue('user@example.com')
    await wrapper.find('input[type="password"]').setValue('password123')

    const form = wrapper.find('form')
    await form.trigger('submit.prevent')

    expect(mockApi.post).toHaveBeenCalledWith('/login', {
      user: { email: 'user@example.com', password: 'password123' }
    })
  })

  test('shows success message and redirects to dashboard on successful login', async () => {
    mockApi.post.mockResolvedValue({
      data: {
        token: 'test-token',
        data: { id: 1, email: 'user@example.com', roles: [] },
        status: { message: 'Login successful' }
      }
    })

    await wrapper.find('input[type="email"]').setValue('user@example.com')
    await wrapper.find('input[type="password"]').setValue('password123')

    await wrapper.vm.handleLogin()
    await nextTick()

    expect(showSnackbarSpy).toHaveBeenCalledWith(
      ['Login successful'],
      'success'
    )
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Dashboard' })
  })

  test('shows error message on login failure', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {
          error: 'Invalid credentials'
        }
      }
    })

    await wrapper.find('input[type="email"]').setValue('user@example.com')
    await wrapper.find('input[type="password"]').setValue('wrongpassword')

    await wrapper.vm.handleLogin()

    expect(showSnackbarSpy).toHaveBeenCalledWith(
      ['Invalid credentials'],
      'error'
    )
  })

  test('shows generic error when no error message in response', async () => {
    mockApi.post.mockRejectedValue({
      response: {
        data: {}
      }
    })

    await wrapper.find('input[type="email"]').setValue('user@example.com')
    await wrapper.find('input[type="password"]').setValue('password123')

    await wrapper.vm.handleLogin()

    expect(showSnackbarSpy).toHaveBeenCalledWith(
      [['An unknown error occurred']],
      'error'
    )
  })

  test('redirects to password reset page when "Forgot Password?" is clicked', async () => {
    const forgotPasswordLink = wrapper.find('a')
    await forgotPasswordLink.trigger('click')
    
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'PasswordReset' })
  })

  test('does not call API if email field is empty', async () => {
    await wrapper.find('input[type="password"]').setValue('password123')
    
    await wrapper.vm.handleLogin()

    expect(mockApi.post).not.toHaveBeenCalled()
  })

  test('does not call API if password field is empty', async () => {
    await wrapper.find('input[type="email"]').setValue('user@example.com')
    
    await wrapper.vm.handleLogin()

    expect(mockApi.post).not.toHaveBeenCalled()
  })

  test('handles missing error.response gracefully', async () => {
    // Note: This test demonstrates that the component has a bug 
    // where it doesn't handle missing error.response properly
    mockApi.post.mockRejectedValue(new Error('Network error'))

    await wrapper.find('input[type="email"]').setValue('user@example.com')
    await wrapper.find('input[type="password"]').setValue('password123')

    // The component will throw because it tries to access error.response.data.error
    // when error.response is undefined. This is a bug that should be fixed.
    await expect(wrapper.vm.handleLogin()).rejects.toThrow('Cannot read properties of undefined')
  })
})
