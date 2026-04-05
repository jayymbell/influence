/* eslint-env jest */
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createTestRouter } from './setup.js'

jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  get: jest.fn(),
  patch: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

const api = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

import AddUserRole from '../../src/components/AddUserRole.vue'

const showSnackbar = jest.fn()

const ROLE = {
  id: 2,
  name: 'staff',
  users: [{ id: 1, email: 'admin@example.com', discarded_at: null }]
}

const ALL_USERS = [
  { id: 1, email: 'admin@example.com', discarded_at: null },
  { id: 2, email: 'alice@example.com', discarded_at: null },
  { id: 3, email: 'inactive@example.com', discarded_at: '2024-01-01' }
]

const mountComponent = (role = ROLE) => mount(AddUserRole, {
  props: { role },
  global: {
    plugins: [createPinia(), createTestRouter()],
    provide: { showSnackbar },
    stubs: {
      'v-row': { template: '<div><slot /></div>' },
      'v-col': { template: '<div><slot /></div>' },
      'v-autocomplete': {
        template: '<input :value="modelValue" @change="$emit(\'update:modelValue\', $event.target.value)" />',
        props: ['modelValue', 'items', 'itemTitle', 'itemValue', 'search']
      },
      'v-btn': { template: '<button type="submit"><slot /></button>' }
    }
  }
})

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('AddUserRole.vue', () => {
  describe('loading users', () => {
    it('fetches users from /users on mount', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      mountComponent()
      await flushPromises()
      expect(api.get).toHaveBeenCalledWith('/users')
    })

    it('filters out users already in the role', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      const wrapper = mountComponent()
      await flushPromises()
      // admin@example.com (id=1) is already in the role — should not appear
      expect(wrapper.vm.availableUsers.map(u => u.id)).not.toContain(1)
    })

    it('filters out discarded users', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      const wrapper = mountComponent()
      await flushPromises()
      // inactive@example.com (id=3) is discarded — should not appear
      expect(wrapper.vm.availableUsers.map(u => u.id)).not.toContain(3)
    })

    it('includes active users not already in the role', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.availableUsers.map(u => u.id)).toContain(2)
    })
  })

  describe('addUserRole', () => {
    it('does nothing when no user is selected', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      const wrapper = mountComponent()
      await flushPromises()

      // selectedUser is null — submit the form
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      expect(api.patch).not.toHaveBeenCalled()
    })

    it('PATCHes the role with merged user_ids on submit', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      api.patch.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()

      // Simulate selecting alice (id=2)
      wrapper.vm.selectedUser = 2
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      // Existing user (id=1) + new user (id=2)
      expect(api.patch).toHaveBeenCalledWith('/roles/2', { role: { user_ids: [1, 2] } })
    })

    it('shows success snackbar and emits user-roles-updated on success', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      api.patch.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()

      wrapper.vm.selectedUser = 2
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      expect(showSnackbar).toHaveBeenCalledWith(['User role added.'], 'success')
      expect(wrapper.emitted('user-roles-updated')).toBeTruthy()
    })

    it('clears selection after successful add', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      api.patch.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()

      wrapper.vm.selectedUser = 2
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      expect(wrapper.vm.selectedUser).toBeNull()
    })

    it('shows error snackbar when PATCH fails', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      api.patch.mockRejectedValue({ response: { data: { errors: ['Not authorized'] } } })
      const wrapper = mountComponent()
      await flushPromises()

      wrapper.vm.selectedUser = 2
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      expect(showSnackbar).toHaveBeenCalledWith(['Not authorized'], 'error')
    })

    it('tracks event on successful add', async () => {
      api.get.mockResolvedValue({ data: { users: ALL_USERS } })
      api.patch.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()

      wrapper.vm.selectedUser = 2
      await wrapper.find('form').trigger('submit')
      await flushPromises()

      expect(trackEvent).toHaveBeenCalledWith('added user role', { user_id: 2, role_id: 2 })
    })
  })
})
