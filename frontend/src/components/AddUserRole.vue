<template>
  <div class="add-user-role">
    <form @submit.prevent="addUserRole">
        <v-row>
            <v-col>
                <v-autocomplete
                v-model="selectedUser"
                :items="filteredUsers"
                item-title="email"
                item-value="id"
                label="Select user by email"
                v-model:search="search"
                style="width: 400px;"
                />
            </v-col>
            <v-col>
                <v-btn type="submit" style="height: 52px; float: right;">Add</v-btn>
            </v-col>
        </v-row>
    </form>
  </div>
</template>

<script setup>
import { inject, ref, onMounted, computed } from 'vue';
import api from '../services/api.js';
import { trackEvent } from "../services/ahoy.js";

const props = defineProps({
  role: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['user-roles-updated']);

const selectedUser = ref(null);
const message = ref('');
const allUsers = ref([]);
const search = ref('');

const showSnackbar = inject('showSnackbar');

onMounted(async () => {
  try {
    const response = await api.get('/users');
    allUsers.value = response.data.users;
  } catch (error) {
    message.value = 'Failed to fetch users.';
  }
});

const availableUsers = computed(() => {
  const idsToRemove = new Set(props.role.users.map(item => item.id));
  return allUsers.value.filter(obj => !idsToRemove.has(obj.id) && !obj.discarded_at);
});

const filteredUsers = computed(() => {
  if (!search.value) return availableUsers.value;
  return availableUsers.value.filter(user =>
    user.email.toLowerCase().includes(search.value.toLowerCase())
  );
});

const addUserRole = async () => {
  if (!selectedUser.value) return;
  try {
    const userIds = props.role.users.map(item => item.id);
    userIds.push(selectedUser.value);
    await api.patch('/roles/' + props.role.id, { role: { user_ids: userIds } });
    trackEvent("added user role", { user_id: selectedUser.value, role_id: props.role.id });
    showSnackbar(["User role added."], 'success');
    emit('user-roles-updated');
    selectedUser.value = null;
  } catch (error) {
    const errors = error.response?.data?.errors || ['An unknown error occurred'];
    showSnackbar(errors, 'error');
  }
};
</script>

<style scoped>
.add-user-role {
  margin-bottom: 1rem;
}
.message {
  margin-top: 0.5rem;
  color: green;
}
</style>
