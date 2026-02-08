/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import PasswordEdit from '../../src/views/PasswordEdit.vue'

// Mock API
jest.mock('../../src/services/api', () => ({
  put: jest.fn()
}))

const mockApi = require('../../src/services/api')

// Mock router
const mockRouter = {
  push: jest.fn()
}

const mockRoute = {
  query: {
    reset_password_token: 'test-reset-token-123'
  }
}

const mockShowSnackbar = jest.fn()

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('PasswordEdit.vue', () => {
  const createComponent = () => {
    return mount(PasswordEdit, {
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

  test('displays new password title', () => {
    const wrapper = createComponent()
    expect(wrapper.text()).toContain('New Password')
  })

  test('initializes with empty password fields', () => {
    const wrapper = createComponent()
    expect(wrapper.vm.password).toBe('')
    expect(wrapper.vm.password_confirmation).toBe('')
  })

  test('updates password when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.password = 'newpassword123'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.password).toBe('newpassword123')
  })

  test('updates password confirmation when changed', async () => {
    const wrapper = createComponent()
    wrapper.vm.password_confirmation = 'newpassword123'
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.password_confirmation).toBe('newpassword123')
  })

  test('shows error when password fields are empty', async () => {
    const wrapper = createComponent()
    await wrapper.vm.resetPassword()
    
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Please enter your new password.'], 'error')
    expect(mockApi.put).not.toHaveBeenCalled()
  })

  test('resets password successfully with valid data', async () => {
    mockApi.put.mockResolvedValue({
      data: {
        status: { message: 'Password reset successfully' }
      }
    })

    const wrapper = createComponent()
    wrapper.vm.password = 'newpassword123'
    wrapper.vm.password_confirmation = 'newpassword123'

    await wrapper.vm.resetPassword()

    expect(mockApi.put).toHaveBeenCalledWith('/password', {
      user: {
        reset_password_token: 'test-reset-token-123',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }
    })
    expect(mockShowSnackbar).toHaveBeenCalledWith(['Password reset successfully'], 'success')
    expect(mockRouter.push).toHaveBeenCalledWith({ name: 'Login' })
  })

  test('handles password reset API errors', async () => {
    mockApi.put.mockRejectedValue({
      response: {
        data: {
          errors: ['Password too weak']
        }
      }
    })

    const wrapper = createComponent()
    wrapper.vm.password = 'weak'
    wrapper.vm.password_confirmation = 'weak'

    await wrapper.vm.resetPassword()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Password too weak'], 'error')
  })

  test('does not submit when only password is filled', async () => {
    const wrapper = createComponent()
    wrapper.vm.password = 'newpassword123'
    wrapper.vm.password_confirmation = ''

    await wrapper.vm.resetPassword()

    expect(mockShowSnackbar).toHaveBeenCalledWith(['Please enter your new password.'], 'error')
    expect(mockApi.put).not.toHaveBeenCalled()
  })
})