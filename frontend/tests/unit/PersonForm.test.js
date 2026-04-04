/* eslint-env jest */
import { mount } from '@vue/test-utils'
import PersonForm from '../../src/components/PersonForm.vue'

const buildForm = (overrides = {}) => ({
  first_name: '',
  last_name: '',
  display_name: '',
  email: '',
  phone: '',
  title: '',
  organization_name: '',
  notes: '',
  ...overrides
})

const mountForm = (form) =>
  mount(PersonForm, {
    props: { form },
    global: {
      stubs: {
        'v-row': { template: '<div class="v-row"><slot /></div>' },
        'v-col': { template: '<div class="v-col"><slot /></div>' },
        'v-text-field': {
          template: '<input :data-label="label" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
          props: ['modelValue', 'label', 'type'],
          emits: ['update:modelValue']
        },
        'v-textarea': {
          template: '<textarea :data-label="label" @input="$emit(\'update:modelValue\', $event.target.value)">{{ modelValue }}</textarea>',
          props: ['modelValue', 'label'],
          emits: ['update:modelValue']
        }
      }
    }
  })

describe('PersonForm.vue', () => {
  test('renders all eight fields', () => {
    const wrapper = mountForm(buildForm())
    const inputs = wrapper.findAll('input')
    const textareas = wrapper.findAll('textarea')
    expect(inputs.length + textareas.length).toBe(8)
  })

  test('marks first_name, last_name and display_name as required with asterisk', () => {
    const wrapper = mountForm(buildForm())
    const labels = wrapper.findAll('[data-label]').map((el) => el.attributes('data-label'))
    expect(labels.find((l) => l.includes('First Name') && l.includes('*'))).toBeTruthy()
    expect(labels.find((l) => l.includes('Last Name') && l.includes('*'))).toBeTruthy()
    expect(labels.find((l) => l.includes('Display Name') && l.includes('*'))).toBeTruthy()
  })

  test('optional fields do not have asterisk', () => {
    const wrapper = mountForm(buildForm())
    const labels = wrapper.findAll('[data-label]').map((el) => el.attributes('data-label'))
    const optional = ['Email', 'Phone', 'Title', 'Organization', 'Notes']
    optional.forEach((name) => {
      const match = labels.find((l) => l.includes(name))
      expect(match).toBeTruthy()
      expect(match).not.toContain('*')
    })
  })

  test('displays passed-in form values', () => {
    const form = buildForm({ first_name: 'Jane', last_name: 'Doe', display_name: 'Jane Doe' })
    const wrapper = mountForm(form)
    const inputs = wrapper.findAll('input')
    const values = inputs.map((i) => i.element.value)
    expect(values).toContain('Jane')
    expect(values).toContain('Doe')
    expect(values).toContain('Jane Doe')
  })

  test('shows required note at the bottom', () => {
    const wrapper = mountForm(buildForm())
    expect(wrapper.text()).toContain('* Required')
  })
})
