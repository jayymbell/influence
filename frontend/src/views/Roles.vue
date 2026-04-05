<template>
    <v-container>
        <h1>Roles</h1>
        <div v-if="!role">
            <AddRole @add-role="onAddRole" />
            <v-divider class="my-4"></v-divider>
            <v-card v-for="role in roles" :key="role.id"  class="pa-3 mt-3" outlined>
                <v-row>
                    <v-col>
                        {{ role.name }} 
                    </v-col>
                    <v-col cols="auto">
                        <v-btn variant="text" size="small" @click="fetchRole(role)">Open</v-btn>
                        <v-btn variant="text" size="small" color="error" @click="deleteRole(role)">Delete</v-btn>
                    </v-col>
                </v-row>
            </v-card>
        </div>
        <div v-else>
        <h2>{{ role_name }}</h2>
        <h3>Users</h3>
        <AddUserRole :role="role" @user-roles-updated="fetchRole(role)"/>
        <v-divider class="my-4"></v-divider>
        <v-card v-for="user in role.users" :key="user.id" class="pa-3 mt-3" outlined>
        <v-row align="center">
            <v-col>
                {{ user.email }}
            <v-chip
                v-if="user.discarded_at"
                label="Inactive"
                style="float: right;"
            >Inactive</v-chip>
            </v-col>
            <v-col cols="auto">
                <v-btn variant="text" size="small" color="error" @click="removeUserRole(user.id)">Remove</v-btn>
            </v-col>
        </v-row>
        </v-card>
        <br/>
        <v-btn variant="text" size="small" class="mt-2" @click="role = ''">Close</v-btn>
        </div>
    </v-container>
</template>

<script>
import { onMounted, ref, inject, computed } from 'vue'
import api from '../services/api.js'
import AddRole from '../components/AddRole.vue'
import AddUserRole from '../components/AddUserRole.vue'
import _ from 'lodash'
import { trackEvent } from "../services/ahoy.js";

export default {
    components: { AddRole, AddUserRole },
    setup() {
        const roles = ref('')
        const role = ref('')
        const showSnackbar = inject('showSnackbar')

        onMounted(() => {
            fetchRoles()
        })

    const role_name = computed({
        get() {
          return _.capitalize(role.value.name)
        }
      });
        
        const fetchRoles = async () => {
            try {
                const response = await api.get('/roles')
                roles.value = response.data.roles
            } catch (error) {
                const e = error.response.data.error || ['An unknown error occurred']
                showSnackbar([e], 'error')
            }
        }

        const onAddRole = async (roleName) => {
            try {
                const response = await api.post('/roles', { name: roleName })
                trackEvent("created role", {role_id: response.data.role.id});
                showSnackbar(['Role created'], 'success')
                fetchRoles()
            } catch (error) {
                const errors = error.response.data.errors || ['An unknown error occurred']
                showSnackbar(errors, 'error')
            }
        }

        const fetchRole = async (r) => {
            try {
                const response = await api.get('/roles/' + r.id)
                role.value = response.data.role
            } catch (error) {
                const e = error.response.data.error || ['An unknown error occurred']
                showSnackbar([e], 'error')
            }
        }

                const deleteRole = async (r) => {
            try {
                const response = await api.delete('/roles/' + r.id)
                trackEvent("deleted role", {role_id: r.id});
                fetchRoles()
                showSnackbar(['Role deleted'], 'success')
            } catch (error) {
                const e = error.response.data.error || ['An unknown error occurred']
                showSnackbar([e], 'error')
            }
        }

        const removeUserRole = async (userId) => {
            try {
                const userIds = role.value.users.map(item => item.id)
                const filteredUserIds = userIds.filter(id => id !== parseInt(userId));
                await api.patch('/roles/'+role.value.id, { role: {user_ids: filteredUserIds }});
                trackEvent("removed user role", {user_id: userId, role_id: role.value.id});
                fetchRole(role.value)
                showSnackbar(['User role removed'], 'success')
            } catch (error) {
                const errors = error.response?.data?.errors || ['An unknown error occurred']
                showSnackbar(errors, 'error')
            }
        };

        return {
            roles,
            onAddRole,
            showSnackbar,
            fetchRole,
            role,
            role_name,
            removeUserRole,
            deleteRole
        }
    }
}
</script>

<style scoped>
/* Add component-specific styles here */
</style>