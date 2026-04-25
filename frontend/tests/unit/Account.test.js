/* eslint-env jest */
import { mount, flushPromises } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { createTestRouter } from './setup.js'
import Account from '../../src/views/Account.vue'
import useUserStore from '../../src/stores/UserStore'

jest.mock('../../src/services/api', () => ({
  defaults: { headers: { common: {} } },
  get: jest.fn(),
  post: jest.fn(),
  put: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))

jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

jest.mock('../../src/components/PersonForm.vue', () => ({
  name: 'PersonForm',
  template: '<div class="person-form" />'
}))

const api = require('../../src/services/api')

const mockShowSnackbar = jest.fn()

const mockPerson = {
  id: 10,
  first_name: 'Jane',
  last_name: 'Doe',
  display_name: 'Jane Doe',
  phone: '555-1234',
  title: 'Manager',
  organization_name: 'Acme',
  email: 'jane@example.com'
}

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

const mountComponent = ({ hasPerson = false } = {}) => {
  const router = createTestRouter()
  const userStore = useUserStore()
  userStore.user = {
    id: 1,
    email: 'user@example.com',
    created_at: '2023-01-01T00:00:00Z',
    roles: [{ id: 1, name: 'admin' }],
    person_id: hasPerson ? mockPerson.id : null
  }

  return mount(Account, {
    global: {
      plugins: [router],
      provide: { showSnackbar: mockShowSnackbar },
      stubs: {
        'v-container': { template: '<div><slot /></div>' },
        'v-card': { template: '<div><slot /></div>' },
        'v-row': { template: '<div><slot /></div>' },
        'v-col': { template: '<div><slot /></div>' },
        'v-btn': { template: '<button @click="$attrs.onClick?.()"><slot /></button>', inheritAttrs: false },
        'v-skeleton-loader': { template: '<div class="skeleton" />' },
        UpdateAccount: { template: '<div class="update-account" />', props: ['mode'] }
      }
    }
  })
}

describe('Account.vue', () => {
  describe('existing account section', () => {
    test('component mounts successfully', () => {
      const wrapper = mountComponent()
      expect(wrapper.exists()).toBe(true)
    })

    test('displays account title', () => {
      const wrapper = mountComponent()
      expect(wrapper.text()).toContain('Account')
    })

    test('shows user email in view mode', async () => {
      const wrapper = mountComponent()
      await wrapper.vm.$nextTick()
      expect(wrapper.text()).toContain('user@example.com')
    })

    test('shows member since year', async () => {
      const wrapper = mountComponent()
      await wrapper.vm.$nextTick()
      expect(wrapper.text()).toContain('member since 2023')
    })

    test('computed est returns correct year', () => {
      const wrapper = mountComponent()
      expect(wrapper.vm.est).toBe(2023)
    })

    test('computed roles joins role names', () => {
      const wrapper = mountComponent()
      expect(wrapper.vm.roles).toBe('admin')
    })

    test('switches to change_email mode', async () => {
      const wrapper = mountComponent()
      wrapper.vm.mode = 'change_email'
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.form_title).toBe('Change Email')
    })

    test('switches to change_password mode', async () => {
      const wrapper = mountComponent()
      wrapper.vm.mode = 'change_password'
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.form_title).toBe('Change Password')
    })

    test('returns to view mode', async () => {
      const wrapper = mountComponent()
      wrapper.vm.mode = 'change_email'
      await wrapper.vm.$nextTick()
      wrapper.vm.mode = 'view'
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.mode).toBe('view')
    })
  })

  describe('profile section — user without person', () => {
    test('does not render profile section', async () => {
      const wrapper = mountComponent({ hasPerson: false })
      await flushPromises()
      expect(wrapper.text()).not.toContain('Profile')
      expect(api.get).not.toHaveBeenCalled()
    })
  })

  describe('profile section — user with person', () => {
    beforeEach(() => {
      api.get.mockResolvedValue({ data: { person: mockPerson } })
    })

    test('renders Profile heading', async () => {
      const wrapper = mountComponent({ hasPerson: true })
      await flushPromises()
      expect(wrapper.text()).toContain('Profile')
    })

    test('fetches person on mount using person_id', async () => {
      mountComponent({ hasPerson: true })
      await flushPromises()
      expect(api.get).toHaveBeenCalledWith(`/people/${mockPerson.id}`)
    })

    test('pre-populates personForm from fetched person', async () => {
      const wrapper = mountComponent({ hasPerson: true })
      await flushPromises()
      expect(wrapper.vm.personForm.first_name).toBe('Jane')
      expect(wrapper.vm.personForm.last_name).toBe('Doe')
      expect(wrapper.vm.personForm.display_name).toBe('Jane Doe')
      expect(wrapper.vm.personForm.phone).toBe('555-1234')
      expect(wrapper.vm.personForm.title).toBe('Manager')
      expect(wrapper.vm.personForm.organization_name).toBe('Acme')
    })

    test('shows snackbar error when fetch fails', async () => {
      api.get.mockRejectedValue(new Error('Network error'))
      mountComponent({ hasPerson: true })
      await flushPromises()
      expect(mockShowSnackbar).toHaveBeenCalledWith(['Failed to load profile.'], 'error')
    })

    test('calls updatePerson with personForm data on save', async () => {
      api.patch.mockResolvedValue({ data: { person: mockPerson } })
      const wrapper = mountComponent({ hasPerson: true })
      await flushPromises()

      await wrapper.vm.saveProfile()

      expect(api.patch).toHaveBeenCalledWith(
        `/people/${mockPerson.id}`,
        { person: wrapper.vm.personForm }
      )
    })

    test('shows success snackbar after save', async () => {
      api.patch.mockResolvedValue({ data: { person: mockPerson } })
      const wrapper = mountComponent({ hasPerson: true })
      await flushPromises()

      await wrapper.vm.saveProfile()
      await flushPromises()

      expect(mockShowSnackbar).toHaveBeenCalledWith(['Profile updated.'], 'success')
    })

    test('shows error snackbar when save fails', async () => {
      api.patch.mockRejectedValue({
        response: { data: { errors: ['Display name is required'] } }
      })
      const wrapper = mountComponent({ hasPerson: true })
      await flushPromises()

      await wrapper.vm.saveProfile()
      await flushPromises()

      expect(mockShowSnackbar).toHaveBeenCalledWith(['Display name is required'], 'error')
    })
  })
})