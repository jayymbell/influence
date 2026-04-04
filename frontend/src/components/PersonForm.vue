<template>
  <v-row>
    <v-col cols="12" sm="4">
      <v-text-field v-model="form.first_name" label="First Name *" />
    </v-col>
    <v-col cols="12" sm="4">
      <v-text-field v-model="form.last_name" label="Last Name *" />
    </v-col>
    <v-col cols="12" sm="4">
      <v-text-field v-model="form.display_name" label="Display Name *" />
    </v-col>
    <v-col v-if="!hideEmail" cols="12" sm="4">
      <v-text-field v-model="form.email" label="Email" type="email" />
    </v-col>
    <v-col cols="12" sm="4">
      <v-text-field v-model="form.phone" label="Phone" />
    </v-col>
    <v-col cols="12" sm="4">
      <v-text-field v-model="form.title" label="Title" />
    </v-col>
    <v-col cols="12">
      <v-text-field v-model="form.organization_name" label="Organization" />
    </v-col>
    <v-col v-if="!hideNotes" cols="12">
      <v-textarea v-model="form.notes" label="Notes" rows="2" auto-grow />
    </v-col>
  </v-row>
  <p class="text-body-2 text-medium-emphasis mt-1">* Required</p>
</template>

<script setup>
defineProps({
  form: {
    type: Object,
    required: true
  },
  hideEmail: {
    type: Boolean,
    default: false
  },
  hideNotes: {
    type: Boolean,
    default: false
  }
})
</script>
