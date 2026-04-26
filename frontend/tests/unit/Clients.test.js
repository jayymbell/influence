/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import Clients from '../../src/views/Clients.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/api', () => ({
  get: jest.fn(),
  post: jest.fn(),
  patch: jest.fn(),
  delete: jest.fn(),
  defaults: { headers: { common: {} } }
}))

jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: (fn) => fn
}))

const api = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')

const mockClients = [
  { id: 1, legal_name: 'Acme Corporation', display_name: 'Acme', status: 'active', discarded_at: null },
  { id: 2, legal_name: 'Beta LLC', display_name: 'Beta LLC', status: 'active', discarded_at: null },
  { id: 3, legal_name: 'Old Corp', display_name: 'Old Corp', status: 'inactive', discarded_at: '2026-01-01T00:00:00.000Z' }
]

const mountComponent = async () => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push('/clients')
  await router.isReady()
  const showSnackbar = jest.fn()
  const wrapper = mount(Clients, {
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar },
      stubs: {
        'v-skeleton-loader': { template: '<div class="v-skeleton-loader" />' },
        'v-card-title': { template: '<div class="v-card-title"><slot /></div>' },
        'v-card-text': { template: '<div class="v-card-text"><slot /></div>' },
        'v-card-actions': { template: '<div class="v-card-actions"><slot /></div>' },
        'v-spacer': { template: '<span class="v-spacer" />' },
        'v-chip': { template: '<span class="v-chip"><slot /></span>' }
      }
    }
  })
  return { wrapper, showSnackbar }
}

beforeEach(() => {
  jest.clearAllMocks()
  api.get.mockResolvedValue({ data: { clients: mockClients } })
})

describe('Clients.vue', () => {
  describe('initial load', () => {
    it('fetches clients on mount', async () => {
      await mountComponent()
      await nextTick()
      expect(api.get).toHaveBeenCalledWith('/clients', { params: {} })
    })

    it('renders skeleton loaders while loading', async () => {
      let resolve
      api.get.mockReturnValue(new Promise((r) => { resolve = r }))
      const { wrapper } = await mountComponent()
      await nextTick()
      expect(wrapper.findAll('.v-skeleton-loader').length).toBeGreaterThan(0)
      resolve({ data: { clients: [] } })
    })

    it('renders a card for each client', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.findAll('.v-card').length).toBeGreaterThanOrEqual(mockClients.length)
    })

    it('shows display_name', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Acme')
      expect(wrapper.text()).toContain('Beta LLC')
    })

    it('shows Inactive chip for inactive clients', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Inactive')
    })

    it('shows "No clients found" when list is empty', async () => {
      api.get.mockResolvedValue({ data: { clients: [] } })
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('No clients found')
    })

    it('calls showSnackbar on fetch error', async () => {
      api.get.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(showSnackbar).toHaveBeenCalledWith(['Forbidden'], 'error')
    })
  })

  describe('search', () => {
    it('passes query param when searching', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      jest.clearAllMocks()
      api.get.mockResolvedValue({ data: { clients: [mockClients[0]] } })
      wrapper.vm.searchQuery = 'acme'
      wrapper.vm.debouncedSearch()
      await nextTick()
      expect(api.get).toHaveBeenCalledWith('/clients', { params: { query: 'acme' } })
    })

    it('clears query and refetches on clear', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      jest.clearAllMocks()
      api.get.mockResolvedValue({ data: { clients: mockClients } })
      wrapper.vm.searchQuery = 'something'
      wrapper.vm.onClearSearch()
      await nextTick()
      expect(wrapper.vm.searchQuery).toBe('')
      expect(api.get).toHaveBeenCalledWith('/clients', { params: {} })
    })

    it('passes discarded=true when showActive is false', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      jest.clearAllMocks()
      api.get.mockResolvedValue({ data: { clients: [] } })
      wrapper.vm.showActive = false
      await wrapper.vm.fetchClients()
      expect(api.get).toHaveBeenCalledWith('/clients', { params: { discarded: 'true' } })
    })
  })

  describe('create dialog', () => {
    it('opens with blank form', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      wrapper.vm.openCreateDialog()
      await nextTick()
      expect(wrapper.vm.dialogOpen).toBe(true)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.legal_name).toBe('')
      expect(wrapper.vm.form.display_name).toBe('')
    })

    it('posts to /clients and shows success', async () => {
      api.post.mockResolvedValue({ data: { client: { id: 10, legal_name: 'New Co', display_name: 'New Co', status: 'active' } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.form = { legal_name: 'New Co', display_name: 'New Co' }
      await wrapper.vm.createClient()
      expect(api.post).toHaveBeenCalledWith('/clients', { client: { legal_name: 'New Co', display_name: 'New Co' } })
      expect(trackEvent).toHaveBeenCalledWith('created client', { client_id: 10 })
      expect(showSnackbar).toHaveBeenCalledWith(['Client created'], 'success')
      expect(wrapper.vm.dialogOpen).toBe(false)
    })

    it('shows server errors on failed create', async () => {
      api.post.mockRejectedValue({ response: { data: { errors: ['Legal name has already been taken'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.openCreateDialog()
      await wrapper.vm.createClient()
      expect(showSnackbar).toHaveBeenCalledWith(['Legal name has already been taken'], 'error')
      expect(wrapper.vm.dialogOpen).toBe(true)
    })
  })

  describe('edit dialog', () => {
    it('fetches client and opens dialog', async () => {
      api.get
        .mockResolvedValueOnce({ data: { clients: mockClients } })
        .mockResolvedValueOnce({ data: { client: mockClients[0] } })
      const { wrapper } = await mountComponent()
      await nextTick()
      await wrapper.vm.openEditDialog(mockClients[0])
      expect(api.get).toHaveBeenCalledWith('/clients/1')
      expect(wrapper.vm.dialogOpen).toBe(true)
      expect(wrapper.vm.form.legal_name).toBe('Acme Corporation')
    })

    it('patches client and shows success', async () => {
      api.patch.mockResolvedValue({ data: { client: mockClients[0] } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[0]
      wrapper.vm.form = { legal_name: 'Acme Corporation', display_name: 'Acme Updated' }
      await wrapper.vm.updateClient()
      expect(api.patch).toHaveBeenCalledWith('/clients/1', { client: { legal_name: 'Acme Corporation', display_name: 'Acme Updated' } })
      expect(trackEvent).toHaveBeenCalledWith('updated client', { client_id: 1 })
      expect(showSnackbar).toHaveBeenCalledWith(['Client updated'], 'success')
      expect(wrapper.vm.dialogOpen).toBe(false)
    })
  })

  describe('deactivate', () => {
    it('opens deactivate confirmation dialog', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[0]
      wrapper.vm.openDeleteDialog()
      expect(wrapper.vm.deleteDialogOpen).toBe(true)
    })

    it('calls DELETE and shows success', async () => {
      api.delete.mockResolvedValue({})
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[0]
      wrapper.vm.dialogOpen = true
      wrapper.vm.deleteDialogOpen = true
      await wrapper.vm.deleteClient()
      expect(api.delete).toHaveBeenCalledWith('/clients/1')
      expect(trackEvent).toHaveBeenCalledWith('deactivated client', { client_id: 1 })
      expect(showSnackbar).toHaveBeenCalledWith(['Client deactivated'], 'success')
      expect(wrapper.vm.deleteDialogOpen).toBe(false)
      expect(wrapper.vm.dialogOpen).toBe(false)
    })

    it('shows error if delete fails', async () => {
      api.delete.mockRejectedValue({ response: { data: { errors: ['Not authorized'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[0]
      await wrapper.vm.deleteClient()
      expect(showSnackbar).toHaveBeenCalledWith(['Not authorized'], 'error')
    })
  })

  describe('reactivate', () => {
    it('posts to reactivate and shows success', async () => {
      api.post.mockResolvedValue({ data: { client: { ...mockClients[2], status: 'active', discarded_at: null } } })
      api.get
        .mockResolvedValueOnce({ data: { clients: mockClients } })
        .mockResolvedValueOnce({ data: { clients: mockClients } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[2]
      await wrapper.vm.reactivateClient()
      expect(api.post).toHaveBeenCalledWith('/clients/3/reactivate')
      expect(trackEvent).toHaveBeenCalledWith('reactivated client', { client_id: 3 })
      expect(showSnackbar).toHaveBeenCalledWith(['Client reactivated'], 'success')
      expect(wrapper.vm.dialogOpen).toBe(false)
    })

    it('shows error on reactivate failure', async () => {
      api.post.mockRejectedValue({ response: { data: { errors: ['Not authorized'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      wrapper.vm.editTarget = mockClients[2]
      await wrapper.vm.reactivateClient()
      expect(showSnackbar).toHaveBeenCalledWith(['Not authorized'], 'error')
    })
  })

  describe('closeDialog', () => {
    it('resets state', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      wrapper.vm.dialogOpen = true
      wrapper.vm.editTarget = mockClients[0]
      wrapper.vm.form.legal_name = 'Edited'
      wrapper.vm.closeDialog()
      expect(wrapper.vm.dialogOpen).toBe(false)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.legal_name).toBe('')
    })
  })
})
