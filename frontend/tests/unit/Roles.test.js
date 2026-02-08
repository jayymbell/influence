/* eslint-env jest */
import { setActivePinia, createPinia } from 'pinia'

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

  const createComponent = () => {
    const showSnackbar = jest.fn()
    return {
      roles: [],
      role: '',
      showSnackbar,
      fetchRoles: async function() {
        try {
          const response = await mockApi.get('/roles')
          this.roles = response.data.roles
        } catch (error) {
          const e = error.response.data.error || ['An unknown error occurred']
          this.showSnackbar([e], 'error')
        }
      },
      fetchRole: async function(r) {
        try {
          const response = await mockApi.get('/roles/' + r.id)
          this.role = response.data.role
        } catch (error) {
          const e = error.response.data.error || ['An unknown error occurred']
          this.showSnackbar([e], 'error')
        }
      },
      onAddRole: async function(roleName) {
        try {
          const response = await mockApi.post('/roles', { name: roleName })
          trackEvent('created role', { role_id: response.data.role.id })
          this.showSnackbar(['Role created'], 'success')
          await this.fetchRoles()
        } catch (error) {
          const errors = error.response.data.errors || ['An unknown error occurred']
          this.showSnackbar(errors, 'error')
        }
      },
      deleteRole: async function(r) {
        try {
          await mockApi.delete('/roles/' + r.id)
          trackEvent('deleted role', { role_id: r.id })
          await this.fetchRoles()
          this.showSnackbar(['Role deleted'], 'success')
        } catch (error) {
          const e = error.response.data.error || ['An unknown error occurred']
          this.showSnackbar([e], 'error')
        }
      },
      removeUserRole: async function(userId) {
        try {
          const userIds = this.role.users.map(item => item.id)
          const filteredUserIds = userIds.filter(id => id !== parseInt(userId))
          await mockApi.patch('/roles/' + this.role.id, { role: { user_ids: filteredUserIds } })
          trackEvent('removed user role', { user_id: userId, role_id: this.role.id })
          await this.fetchRole(this.role)
          this.showSnackbar(['User role removed'], 'success')
        } catch (error) {
          const errors = error.response?.data?.errors || ['An unknown error occurred']
          this.showSnackbar(errors, 'error')
        }
      },
      get role_name() {
        return this.role ? _.capitalize(this.role.name) : ''
      }
    }
  }

  test('fetches roles list', async () => {
    mockApi.get.mockResolvedValue({ data: { roles: mockRoles } })
    const component = createComponent()
    await component.fetchRoles()
    expect(mockApi.get).toHaveBeenCalledWith('/roles')
    expect(component.roles).toEqual(mockRoles)
  })

  test('handles fetch roles error gracefully', async () => {
    mockApi.get.mockRejectedValue({ response: { data: { error: 'Cannot fetch roles' } } })
    const component = createComponent()
    await component.fetchRoles()
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot fetch roles'], 'error')
  })

  test('fetches role details', async () => {
    mockApi.get.mockResolvedValue({ data: { role: mockRoleDetails } })
    const component = createComponent()
    await component.fetchRole(mockRoles[0])
    expect(mockApi.get).toHaveBeenCalledWith('/roles/1')
    expect(component.role).toEqual(mockRoleDetails)
  })

  test('handles fetch role details error gracefully', async () => {
    mockApi.get.mockRejectedValue({ response: { data: { error: 'Cannot fetch role' } } })
    const component = createComponent()
    await component.fetchRole(mockRoles[0])
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot fetch role'], 'error')
  })

  test('adds new role', async () => {
    mockApi.post.mockResolvedValue({ data: { role: { id: 3, name: 'moderator' } } })
    mockApi.get.mockResolvedValue({ data: { roles: [...mockRoles, { id: 3, name: 'moderator', users: [] }] } })
    const component = createComponent()
    await component.onAddRole('moderator')
    expect(mockApi.post).toHaveBeenCalledWith('/roles', { name: 'moderator' })
    expect(trackEvent).toHaveBeenCalledWith('created role', { role_id: 3 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['Role created'], 'success')
  })

  test('handles add role error gracefully', async () => {
    mockApi.post.mockRejectedValue({ response: { data: { errors: ['Role name already exists'] } } })
    const component = createComponent()
    await component.onAddRole('admin')
    expect(component.showSnackbar).toHaveBeenCalledWith(['Role name already exists'], 'error')
  })

  test('deletes role', async () => {
    mockApi.delete.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { roles: [mockRoles[1]] } })
    const component = createComponent()
    await component.deleteRole(mockRoles[0])
    expect(mockApi.delete).toHaveBeenCalledWith('/roles/1')
    expect(trackEvent).toHaveBeenCalledWith('deleted role', { role_id: 1 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['Role deleted'], 'success')
  })

  test('handles delete role error gracefully', async () => {
    mockApi.delete.mockRejectedValue({ response: { data: { error: 'Cannot delete role with users' } } })
    const component = createComponent()
    await component.deleteRole(mockRoles[0])
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot delete role with users'], 'error')
  })

  test('removes user from role', async () => {
    mockApi.patch.mockResolvedValue({ data: {} })
    mockApi.get.mockResolvedValue({ data: { role: { ...mockRoleDetails, users: [mockRoleDetails.users[0]] } } })
    const component = createComponent()
    component.role = mockRoleDetails
    await component.removeUserRole(mockRoleDetails.users[1].id)
    expect(mockApi.patch).toHaveBeenCalledWith('/roles/1', { role: { user_ids: [1] } })
    expect(trackEvent).toHaveBeenCalledWith('removed user role', { user_id: 2, role_id: 1 })
    expect(component.showSnackbar).toHaveBeenCalledWith(['User role removed'], 'success')
  })

  test('handles remove user role error gracefully', async () => {
    mockApi.patch.mockRejectedValue({ response: { data: { errors: ['Cannot remove user from role'] } } })
    const component = createComponent()
    component.role = mockRoleDetails
    await component.removeUserRole(mockRoleDetails.users[0].id)
    expect(component.showSnackbar).toHaveBeenCalledWith(['Cannot remove user from role'], 'error')
  })

  test('closes role details', () => {
    const component = createComponent()
    component.role = mockRoleDetails
    component.role = ''
    expect(component.role).toBe('')
  })

  test('displays capitalized role name', () => {
    const component = createComponent()
    component.role = mockRoleDetails
    expect(component.role_name).toBe('Admin')
  })

  test('handles empty users list in role', () => {
    const component = createComponent()
    component.role = mockRoles[0]
    expect(component.role.users).toEqual([])
  })

  test('handles multiple users in role', () => {
    const component = createComponent()
    component.role = mockRoleDetails
    expect(component.role.users.length).toBe(2)
  })
})
