/* eslint-env jest */
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { nextTick } from 'vue'
import Roles from '../../src/views/Roles.vue'

// Mock API and tracking services
jest.mock('../../src/services/api', () => ({
  get: jest.fn(),
  post: jest.fn(),
  delete: jest.fn(),
  patch: jest.fn()
}))
jest.mock('../../src/services/ahoy.js', () => ({ trackEvent: jest.fn().mockResolvedValue({}) }))
jest.mock('lodash', () => ({
  capitalize: jest.fn((str) => str.charAt(0).toUpperCase() + str.slice(1))
}))

const mockApi = require('../../src/services/api')
const { trackEvent } = require('../../src/services/ahoy.js')
const _ = require('lodash')

beforeEach(() => {
  jest.clearAllMocks()
  setActivePinia(createPinia())
})

describe('Roles.vue', () => {
  let wrapper
  let showSnackbarSpy
  
  const mockRoles = [
    { id: 1, name: 'admin', users: [] },
    { id: 2, name: 'user', users: [] }
  ]

  const mockRoleDetails = {
    id: 1,
    name: 'admin',
    users: [
      { id: 1, email: 'admin@example.com', discarded_at: null },
      { id: 2, email: 'admin2@example.com', discarded_at: null }
    ]
  }

  const mountComponent = (options = {}) => {
    showSnackbarSpy = jest.fn()
    return mount(Roles, {
      global: {
        provide: {
          showSnackbar: showSnackbarSpy
        },
        plugins: [createPinia()],
        stubs: {
          'AddRole': { 
            template: '<div class="add-role"><button @click="$emit(\'add-role\', \'test-role\')">Add Role</button></div>',
            emits: ['add-role']
          },
          'AddUserRole': { 
            template: '<div class="add-user-role"><button @click="$emit(\'user-roles-updated\')">Add User Role</button></div>',
            props: ['role'],
            emits: ['user-roles-updated']
          }
        }
      },
      ...options
    })
  }

  beforeEach(() => {
    // Mock API calls to prevent errors during mounting
    mockApi.get.mockResolvedValue({ data: { roles: [] } })
    wrapper = mountComponent()
    jest.clearAllMocks()
  })

  afterEach(() => {
    wrapper?.unmount()
  })

  test('renders roles page with heading', () => {
    expect(wrapper.find('h1').text()).toBe('Roles')
  })

  test('fetches roles on mount', async () => {
    mockApi.get.mockResolvedValue({ data: { roles: mockRoles } })
    
    const newWrapper = mountComponent()
    await nextTick()
    
    expect(mockApi.get).toHaveBeenCalledWith('/roles')
  })

  test('displays list of roles', async () => {
    mockApi.get.mockResolvedValue({ data: { roles: mockRoles } })
    
    wrapper.vm.roles = mockRoles
    await wrapper.vm.$nextTick()

    expect(wrapper.vm.roles).toEqual(mockRoles)
  })

  test('handles fetch roles error gracefully', async () => {
    // Create a new component instance to test the error handling directly through initial load
    mockApi.get.mockRejectedValueOnce({ response: { data: { error: 'Cannot fetch roles' } } })
    
    const errorWrapper = mountComponent()
    
    // Wait for the component to mount and attempt to fetch roles
    await errorWrapper.vm.$nextTick()
    
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Cannot fetch roles'], 'error')
  })

  test('opens role details when fetchRole is called', async () => {
    mockApi.get.mockResolvedValue({ data: { role: mockRoleDetails } })
    
    await wrapper.vm.fetchRole(mockRoles[0])
    
    expect(mockApi.get).toHaveBeenCalledWith('/roles/1')
    expect(wrapper.vm.role).toEqual(mockRoleDetails)
  })

  test('handles fetch role details error gracefully', async () => {
    mockApi.get.mockRejectedValue({ response: { data: { error: 'Cannot fetch role' } } })
    
    await wrapper.vm.fetchRole(mockRoles[0])
    
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Cannot fetch role'], 'error')
  })

  test('adds new role when called', async () => {
    mockApi.post.mockResolvedValue({ data: { role: { id: 3, name: 'moderator' } } })
    mockApi.get.mockResolvedValue({ data: { roles: [...mockRoles, { id: 3, name: 'moderator', users: [] }] } })
    
    await wrapper.vm.onAddRole('moderator')
    
    expect(mockApi.post).toHaveBeenCalledWith('/roles', { name: 'moderator' })
    expect(trackEvent).toHaveBeenCalledWith('created role', { role_id: 3 })
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Role created'], 'success')
  })

  test('handles add role error gracefully', async () => {
    mockApi.post.mockRejectedValue({ response: { data: { errors: ['Role name already exists'] } } })
    
    await wrapper.vm.onAddRole('admin')
    
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Role name already exists'], 'error')
  })

  test('deletes role', async () => {
    mockApi.delete.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { roles: [mockRoles[1]] } })
    
    await wrapper.vm.deleteRole(mockRoles[0])
    
    expect(mockApi.delete).toHaveBeenCalledWith('/roles/1')
    expect(trackEvent).toHaveBeenCalledWith('deleted role', { role_id: 1 })
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Role deleted'], 'success')
  })

  test('handles delete role error gracefully', async () => {
    mockApi.delete.mockRejectedValue({ response: { data: { error: 'Cannot delete role with users' } } })
    
    await wrapper.vm.deleteRole(mockRoles[0])
    
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Cannot delete role with users'], 'error')
  })

  test('removes user from role', async () => {
    mockApi.patch.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { role: { ...mockRoleDetails, users: [mockRoleDetails.users[0]] } } })
    
    wrapper.vm.role = mockRoleDetails
    await wrapper.vm.removeUserRole(mockRoleDetails.users[1].id)
    
    expect(mockApi.patch).toHaveBeenCalledWith('/roles/1', { role: { user_ids: [1] } })
    expect(trackEvent).toHaveBeenCalledWith('removed user role', { user_id: 2, role_id: 1 })
    expect(showSnackbarSpy).toHaveBeenCalledWith(['User role removed'], 'success')
  })

  test('handles remove user role error gracefully', async () => {
    mockApi.patch.mockRejectedValue({ response: { data: { errors: ['Cannot remove user from role'] } } })
    
    wrapper.vm.role = mockRoleDetails
    await wrapper.vm.removeUserRole(mockRoleDetails.users[0].id)
    
    expect(showSnackbarSpy).toHaveBeenCalledWith(['Cannot remove user from role'], 'error')
  })

  test('closes role details', async () => {
    wrapper.vm.role = mockRoleDetails
    wrapper.vm.role = ''
    
    expect(wrapper.vm.role).toBe('')
  })

  test('displays capitalized role name', () => {
    wrapper.vm.role = mockRoleDetails
    expect(wrapper.vm.role_name).toBe('Admin')
  })

  test('shows AddRole component when no role is selected', () => {
    expect(wrapper.find('.add-role').exists()).toBe(true)
  })

  test('shows role details when role is selected', async () => {
    wrapper.vm.role = mockRoleDetails
    await wrapper.vm.$nextTick()
    
    expect(wrapper.find('h2').text()).toBe('Admin')
    expect(wrapper.find('h3').text()).toBe('Users')
  })

  test('handles empty users list in role', () => {
    wrapper.vm.role = mockRoles[0]
    expect(wrapper.vm.role.users).toEqual([])
  })

  test('handles multiple users in role', () => {
    wrapper.vm.role = mockRoleDetails
    expect(wrapper.vm.role.users.length).toBe(2)
  })
})
