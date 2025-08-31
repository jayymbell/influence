<template>
    <v-form @submit.prevent="submitRole">
        <v-row>
            <v-col>
                <v-text-field
                    v-model="roleName"
                    label="Role Name"
                    style="width: 400px;"
                    required
                />
            </v-col>
            <v-col>
                <v-btn type="submit" style="height: 52px; float: right;">Add</v-btn>
            </v-col>
        </v-row>
    </v-form>
</template>

<script setup>
import { ref } from 'vue'

const roleName = ref('')

const emit = defineEmits(['add-role'])

function submitRole() {
  if (roleName.value.trim()) {
    emit('add-role', roleName.value.trim())
    roleName.value = ''
  }
}
</script>

<style scoped>
/* Add any custom styles here */
</style>
