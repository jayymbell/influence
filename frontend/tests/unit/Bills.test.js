/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import Bills from '../../src/views/Bills.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/bills', () => ({
  getAll: jest.fn(),
  get:    jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  destroy: jest.fn(),
}))

jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn() }))

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: (fn) => fn,
}))

const billsApi = require('../../src/services/bills')

const mockBills = [
  { id: 1, title: 'Budget Reform', bill_number: 'HB 100', status: 'introduced',   chamber: 'house',   session_year: 2026, tags: ['healthcare'] },
  { id: 2, title: 'Transport Act',  bill_number: 'SB 200', status: 'signed',       chamber: 'senate',  session_year: 2026, tags: [] },
  { id: 3, title: 'Energy Bill',    bill_number: null,      status: 'failed',       chamber: null,      session_year: null, tags: ['energy'] },
]

const mountComponent = async () => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push('/bills')
  await router.isReady()
  const showSnackbar = jest.fn()
  const wrapper = mount(Bills, {
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar },
      stubs: {
        'v-skeleton-loader': { template: '<div class="v-skeleton-loader" />' },
        'v-card-title':   { template: '<div class="v-card-title"><slot /></div>' },
        'v-card-text':    { template: '<div class="v-card-text"><slot /></div>' },
        'v-card-actions': { template: '<div class="v-card-actions"><slot /></div>' },
        'v-spacer':       { template: '<span class="v-spacer" />' },
        'v-chip':         { template: '<span class="v-chip"><slot /></span>' },
        'v-textarea':     { template: '<textarea />' },
        'v-combobox':     { template: '<input />' },
        'v-select':       { template: '<select />' },
      },
    },
  })
  return { wrapper, showSnackbar }
}

beforeEach(() => {
  jest.resetAllMocks()
  billsApi.getAll.mockResolvedValue({ data: { bills: [...mockBills] } })
})

describe('Bills.vue', () => {
  describe('initial load', () => {
    it('fetches bills on mount', async () => {
      await mountComponent()
      await nextTick()
      expect(billsApi.getAll).toHaveBeenCalledWith({})
    })

    it('renders skeleton loaders while loading', async () => {
      let resolve
      billsApi.getAll.mockReturnValue(new Promise((r) => { resolve = r }))
      const { wrapper } = await mountComponent()
      await nextTick()
      expect(wrapper.findAll('.v-skeleton-loader').length).toBeGreaterThan(0)
      resolve({ data: { bills: [] } })
    })

    it('renders a card for each bill', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.findAll('.v-card').length).toBeGreaterThanOrEqual(mockBills.length)
    })

    it('shows bill titles', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('Budget Reform')
      expect(wrapper.text()).toContain('Transport Act')
    })

    it('shows bill numbers', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('HB 100')
      expect(wrapper.text()).toContain('SB 200')
    })

    it('renders tags as chips', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('healthcare')
      expect(wrapper.text()).toContain('energy')
    })

    it('shows "No bills found" when empty', async () => {
      billsApi.getAll.mockResolvedValue({ data: { bills: [] } })
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(wrapper.text()).toContain('No bills found')
    })

    it('calls showSnackbar on fetch error', async () => {
      billsApi.getAll.mockRejectedValue({ response: { data: { errors: ['Forbidden'] } } })
      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()
      expect(showSnackbar).toHaveBeenCalledWith(['Forbidden'], 'error')
    })
  })

  describe('create bill', () => {
    it('calls billsApi.create and prepends to list on success', async () => {
      const newBill = { id: 4, title: 'New Bill', bill_number: 'HB 300', status: 'introduced', chamber: 'house', session_year: 2026, tags: [] }
      billsApi.create.mockResolvedValue({ data: { bill: newBill } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.form.title = 'New Bill'
      await wrapper.vm.createBill()
      await nextTick()

      expect(billsApi.create).toHaveBeenCalled()
      expect(showSnackbar).toHaveBeenCalledWith(['Bill created.'], 'success')
    })

    it('shows error snackbar on create failure', async () => {
      billsApi.create.mockRejectedValue({ response: { data: { errors: ['Title is too short'] } } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.form.title = 'X'
      await wrapper.vm.createBill()
      await nextTick()

      expect(showSnackbar).toHaveBeenCalledWith(['Title is too short'], 'error')
    })
  })

  describe('update bill', () => {
    it('calls billsApi.update and updates list on success', async () => {
      const updated = { ...mockBills[0], title: 'Updated Title' }
      billsApi.update.mockResolvedValue({ data: { bill: updated } })
      billsApi.get.mockResolvedValue({ data: { bill: mockBills[0] } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.editTarget = mockBills[0]
      wrapper.vm.form = { title: 'Updated Title', bill_number: 'HB 100', chamber: 'house', session_year: 2026, status: 'introduced', description: '', notes: '', tags: [] }
      await wrapper.vm.updateBill()
      await nextTick()

      expect(billsApi.update).toHaveBeenCalledWith(1, expect.objectContaining({ title: 'Updated Title' }))
      expect(showSnackbar).toHaveBeenCalledWith(['Bill updated.'], 'success')
    })

    it('shows error snackbar on update failure', async () => {
      billsApi.update.mockRejectedValue({ response: { data: { errors: ['Title is blank'] } } })

      const { wrapper, showSnackbar } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.editTarget = mockBills[0]
      wrapper.vm.form = { title: '', bill_number: '', chamber: null, session_year: null, status: 'introduced', description: '', notes: '', tags: [] }
      await wrapper.vm.updateBill()
      await nextTick()

      expect(showSnackbar).toHaveBeenCalledWith(['Title is blank'], 'error')
    })
  })

  describe('formatStatus helper', () => {
    it('formats snake_case to title case', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.formatStatus('in_committee')).toBe('In Committee')
      expect(wrapper.vm.formatStatus('passed_both_chambers')).toBe('Passed Both Chambers')
      expect(wrapper.vm.formatStatus('introduced')).toBe('Introduced')
    })

    it('returns empty string for falsy input', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.formatStatus(null)).toBe('')
      expect(wrapper.vm.formatStatus('')).toBe('')
    })
  })

  describe('statusColor helper', () => {
    it('returns correct colors for known statuses', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.statusColor('signed')).toBe('success')
      expect(wrapper.vm.statusColor('vetoed')).toBe('error')
      expect(wrapper.vm.statusColor('introduced')).toBe('blue')
    })

    it('returns default for unknown status', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.statusColor('unknown_status')).toBe('default')
    })
  })

  describe('chamberColor helper', () => {
    it('returns blue-grey for house', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.chamberColor('house')).toBe('blue-grey')
    })

    it('returns purple for senate', async () => {
      const { wrapper } = await mountComponent()
      expect(wrapper.vm.chamberColor('senate')).toBe('purple')
    })
  })

  describe('dialog state', () => {
    it('openCreateDialog opens dialog with empty form', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()
      await nextTick()

      wrapper.vm.openCreateDialog()
      await nextTick()

      expect(wrapper.vm.dialogOpen).toBe(true)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.title).toBe('')
    })

    it('closeDialog resets form and closes dialog', async () => {
      const { wrapper } = await mountComponent()
      await nextTick()

      wrapper.vm.dialogOpen = true
      wrapper.vm.editTarget = mockBills[0]
      wrapper.vm.closeDialog()
      await nextTick()

      expect(wrapper.vm.dialogOpen).toBe(false)
      expect(wrapper.vm.editTarget).toBeNull()
      expect(wrapper.vm.form.title).toBe('')
    })
  })
})
