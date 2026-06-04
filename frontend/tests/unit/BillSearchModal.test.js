/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import BillSearchModal from '../../src/components/BillSearchModal.vue'
import { createTestRouter } from './setup'

jest.mock('../../src/services/bills', () => ({
  search:      jest.fn(),
  importBill:  jest.fn(),
  linkExternal: jest.fn(),
}))

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: (fn) => fn,
}))

const billsApi = require('../../src/services/bills')

const mockResult = {
  external_id:      'ocd-bill/1',
  bill_number:      'HF 100',
  title:            'Education Funding Act',
  chamber:          'house',
  session_year:     2026,
  already_imported: false,
  internal_id:      null,
}

const mountModal = async (propsData = {}) => {
  const pinia = createPinia()
  setActivePinia(pinia)
  const router = createTestRouter()
  await router.push('/bills')
  await router.isReady()
  const showSnackbar = jest.fn()

  const wrapper = mount(BillSearchModal, {
    props: {
      modelValue: true,
      mode: 'import',
      ...propsData,
    },
    global: {
      plugins: [pinia, router],
      provide: { showSnackbar },
      stubs: {
        'v-dialog':          { template: '<div v-if="modelValue"><slot /></div>', props: ['modelValue'] },
        'v-card':            { template: '<div class="v-card"><slot /></div>' },
        'v-card-title':      { template: '<div class="v-card-title"><slot /></div>' },
        'v-card-text':       { template: '<div class="v-card-text"><slot /></div>' },
        'v-card-actions':    { template: '<div class="v-card-actions"><slot /></div>' },
        'v-spacer':          { template: '<span />' },
        'v-text-field':      {
          template: '<input :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
          props: ['modelValue'],
          emits: ['update:modelValue'],
        },
        'v-skeleton-loader': { template: '<div class="v-skeleton-loader" />' },
        'v-alert':           { template: '<div class="v-alert"><slot /></div>' },
        'v-table':           { template: '<table><slot /></table>' },
        'v-chip':            { template: '<span class="v-chip"><slot /></span>', props: ['to'] },
        'v-btn':             {
          template: '<button class="v-btn" :disabled="disabled" @click="$emit(\'click\')"><slot /></button>',
          props: ['disabled', 'loading', 'to', 'variant', 'size', 'color'],
          emits: ['click'],
        },
      },
    },
  })

  return { wrapper, showSnackbar, router }
}

beforeEach(() => {
  jest.clearAllMocks()
})

describe('BillSearchModal', () => {
  describe('rendering', () => {
    it('shows import title in import mode', async () => {
      const { wrapper } = await mountModal({ mode: 'import' })
      expect(wrapper.find('.v-card-title').text()).toContain('Search Open States')
    })

    it('shows link title in link mode', async () => {
      const { wrapper } = await mountModal({ mode: 'link', billId: 5 })
      expect(wrapper.find('.v-card-title').text()).toContain('Link to Open States')
    })

    it('shows initial prompt when no search has been made', async () => {
      const { wrapper } = await mountModal()
      expect(wrapper.text()).toContain('Type a keyword or bill number')
    })
  })

  describe('searching', () => {
    it('calls billsApi.search on input and renders rows', async () => {
      billsApi.search.mockResolvedValue({ data: { results: [mockResult] } })
      const { wrapper } = await mountModal()

      await wrapper.vm.doSearch.call(
        wrapper.vm,
        // set query first
        (() => { wrapper.vm.query = 'education' })() || undefined
      )
      wrapper.vm.query = 'education'
      await wrapper.vm.doSearch()
      await nextTick()

      expect(billsApi.search).toHaveBeenCalledWith('education')
      expect(wrapper.vm.results).toHaveLength(1)
      expect(wrapper.vm.searched).toBe(true)
    })

    it('shows empty state when search returns no results', async () => {
      billsApi.search.mockResolvedValue({ data: { results: [] } })
      const { wrapper } = await mountModal()

      wrapper.vm.query = 'xyzxyz'
      await wrapper.vm.doSearch()
      await nextTick()

      expect(wrapper.vm.results).toHaveLength(0)
      expect(wrapper.vm.searched).toBe(true)
    })

    it('sets error state on API failure', async () => {
      billsApi.search.mockRejectedValue({
        response: { data: { errors: ['Service unavailable'] } },
      })
      const { wrapper } = await mountModal()

      wrapper.vm.query = 'education'
      await wrapper.vm.doSearch()
      await nextTick()

      expect(wrapper.vm.error).toBe('Service unavailable')
      expect(wrapper.vm.results).toHaveLength(0)
    })

    it('clearSearch resets state', async () => {
      billsApi.search.mockResolvedValue({ data: { results: [mockResult] } })
      const { wrapper } = await mountModal()

      wrapper.vm.query = 'education'
      await wrapper.vm.doSearch()
      await nextTick()

      wrapper.vm.clearSearch()
      expect(wrapper.vm.results).toHaveLength(0)
      expect(wrapper.vm.searched).toBe(false)
      expect(wrapper.vm.error).toBeNull()
    })

    it('does nothing when query is blank', async () => {
      const { wrapper } = await mountModal()
      wrapper.vm.query = '   '
      await wrapper.vm.doSearch()
      expect(billsApi.search).not.toHaveBeenCalled()
    })
  })

  describe('alreadyImportedLink', () => {
    it('returns a route object when internal_id is present', async () => {
      const { wrapper } = await mountModal()
      const result = { ...mockResult, already_imported: true, internal_id: 42 }
      expect(wrapper.vm.alreadyImportedLink(result)).toEqual({ name: 'BillShow', params: { id: 42 } })
    })

    it('returns null when internal_id is absent', async () => {
      const { wrapper } = await mountModal()
      expect(wrapper.vm.alreadyImportedLink(mockResult)).toBeNull()
    })
  })

  describe('import mode — handleImport', () => {
    it('calls importBill and navigates to BillShow on success', async () => {
      billsApi.importBill.mockResolvedValue({ data: { bill: { id: 7 } } })
      const { wrapper, router } = await mountModal({ mode: 'import' })
      const pushSpy = jest.spyOn(router, 'push')

      await wrapper.vm.handleImport(mockResult)
      await nextTick()

      expect(billsApi.importBill).toHaveBeenCalledWith('ocd-bill/1')
      expect(pushSpy).toHaveBeenCalledWith({ name: 'BillShow', params: { id: 7 } })
    })

    it('shows snackbar on import failure', async () => {
      billsApi.importBill.mockRejectedValue({
        response: { data: { errors: ['Import failed.'] } },
      })
      const { wrapper, showSnackbar } = await mountModal({ mode: 'import' })

      await wrapper.vm.handleImport(mockResult)
      await nextTick()

      expect(showSnackbar).toHaveBeenCalledWith(['Import failed.'], 'error')
    })

    it('resets actionLoadingId after import', async () => {
      billsApi.importBill.mockResolvedValue({ data: { bill: { id: 7 } } })
      const { wrapper } = await mountModal({ mode: 'import' })

      await wrapper.vm.handleImport(mockResult)
      await nextTick()

      expect(wrapper.vm.actionLoadingId).toBeNull()
    })
  })

  describe('link mode — handleLink', () => {
    it('calls linkExternal and emits linked on success', async () => {
      billsApi.linkExternal.mockResolvedValue({ data: { bill: { id: 5 } } })
      const { wrapper } = await mountModal({ mode: 'link', billId: 5 })

      await wrapper.vm.handleLink(mockResult)
      await nextTick()

      expect(billsApi.linkExternal).toHaveBeenCalledWith(5, 'ocd-bill/1')
      const emitted = wrapper.emitted('linked')
      expect(emitted).toHaveLength(1)
    })

    it('shows snackbar on link failure', async () => {
      billsApi.linkExternal.mockRejectedValue({
        response: { data: { errors: ['Already linked to another bill.'] } },
      })
      const { wrapper, showSnackbar } = await mountModal({ mode: 'link', billId: 5 })

      await wrapper.vm.handleLink(mockResult)
      await nextTick()

      expect(showSnackbar).toHaveBeenCalledWith(['Already linked to another bill.'], 'error')
    })
  })

  describe('close', () => {
    it('emits update:modelValue false', async () => {
      const { wrapper } = await mountModal()
      wrapper.vm.close()
      const emitted = wrapper.emitted('update:modelValue')
      expect(emitted).toBeDefined()
      expect(emitted[0]).toEqual([false])
    })
  })

  describe('watch modelValue', () => {
    it('resets state when dialog re-opens', async () => {
      billsApi.search.mockResolvedValue({ data: { results: [mockResult] } })
      const { wrapper } = await mountModal({ modelValue: true })

      wrapper.vm.query = 'test'
      await wrapper.vm.doSearch()
      await nextTick()
      expect(wrapper.vm.results).toHaveLength(1)

      // Close then reopen
      await wrapper.setProps({ modelValue: false })
      await wrapper.setProps({ modelValue: true })
      await nextTick()

      expect(wrapper.vm.query).toBe('')
      expect(wrapper.vm.results).toHaveLength(0)
      expect(wrapper.vm.searched).toBe(false)
    })
  })
})
