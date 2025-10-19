import {computed, ref} from 'vue'
import {defineStore} from 'pinia'
import api from '../services/api'
import { trackEvent } from "../services/ahoy.js";

const useUserStore = defineStore("UserStore", () => {
    
    // state initialization with error handling
    const initUser = () => {
        try {
            const stored = localStorage.getItem('user')
            // Check if the stored value is valid before parsing
            if (!stored || stored === 'undefined' || stored === 'null') {
                return null
            }
            return JSON.parse(stored)
        } catch (e) {
            console.error('Error parsing stored user:', e)
            // Clean up invalid storage
            localStorage.removeItem('user')
            return null
        }
    }
    
    // Initialize state
    const user = ref(initUser())
    const bearerToken = ref(localStorage.getItem('bearerToken'))
    
    // Clean up invalid token if it exists
    if (bearerToken.value === 'undefined' || bearerToken.value === 'null') {
        localStorage.removeItem('bearerToken')
        bearerToken.value = null
    }

    // Ensure Authorization header is set on store init (for refresh)
    const setAuthHeader = (token) => {
        if (token) {
            // Ensure token doesn't already have 'Bearer ' prefix
            const tokenValue = token.startsWith('Bearer ') ? token : `Bearer ${token}`
            api.defaults.headers.common['Authorization'] = tokenValue
        } else {
            delete api.defaults.headers.common['Authorization']
        }
    }

    // Initialize auth header
    setAuthHeader(bearerToken.value)

    // getters
    const isLoggedIn = computed(() => bearerToken.value !== null)

    const hasRole = (roleName) => {
        if (!user.value || !user.value.roles) return false;
        return user.value.roles.map(item => item.name).includes(roleName);
    }

    //actions

    const login = async (data) => {
        const response = await api.post(`/login`, data)
        if (response.data.token) {
            // Store token first
            bearerToken.value = response.data.token
            localStorage.setItem('bearerToken', bearerToken.value)
            
            // Store user if we have valid data
            if (response.data.data) {
                user.value = response.data.data
                try {
                    localStorage.setItem('user', JSON.stringify(response.data.data))
                } catch (e) {
                    console.error('Error storing user data:', e)
                }
            } else {
                console.error('No user data received in login response:', response.data)
            }
            
            // Update auth header for future requests
            setAuthHeader(response.data.token)
            // Track login event with new token
            await trackEvent('logged in', {}, response.data.token)
        } else {
            console.error('No token received in login response')
        }

        return response
    }

    const logout = async () => {
        const token = bearerToken.value
        if (!isLoggedIn.value) {
          return { data: { message: 'Already signed out' } }
        }
        
        try {
          // Track the logout event first while we still have valid auth
          await trackEvent("logged out", {}, token)
          
          // Then try to log out on the server
          const response = await api.delete(`/logout`)
          return response
        } catch (error) {
          console.warn('Logout error:', error)
          return { data: { message: 'Error during logout, but session cleared' } }
        } finally {
          // Always clean up local state
          bearerToken.value = null
          user.value = null
          localStorage.removeItem('bearerToken')
          localStorage.removeItem('user')
          setAuthHeader(null)
        }
    }

    const update = async (data) => {
        const response = await api.patch(`/users/${user.value.id}`, data)
        user.value = response.data.user
        localStorage.setItem('user', JSON.stringify(user.value))
        return response 
    }
    
    
    

    return {user, bearerToken, isLoggedIn, login, logout, update, hasRole}
})

export default useUserStore