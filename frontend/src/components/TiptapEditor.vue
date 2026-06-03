<template>
  <div class="tiptap-wrapper" :class="{ 'tiptap-wrapper--focused': editor?.isFocused }">
    <!-- Toolbar -->
    <div class="tiptap-toolbar">
      <v-btn-group density="compact" variant="text" divided>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('bold') ? 'primary' : undefined"
          title="Bold (Ctrl+B)"
          @click="editor?.chain().focus().toggleBold().run()"
        >
          <v-icon>mdi-format-bold</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('italic') ? 'primary' : undefined"
          title="Italic (Ctrl+I)"
          @click="editor?.chain().focus().toggleItalic().run()"
        >
          <v-icon>mdi-format-italic</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('strike') ? 'primary' : undefined"
          title="Strikethrough"
          @click="editor?.chain().focus().toggleStrike().run()"
        >
          <v-icon>mdi-format-strikethrough</v-icon>
        </v-btn>
      </v-btn-group>

      <v-divider vertical class="mx-1" />

      <v-btn-group density="compact" variant="text" divided>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('heading', { level: 2 }) ? 'primary' : undefined"
          title="Heading 2"
          @click="editor?.chain().focus().toggleHeading({ level: 2 }).run()"
        >
          <v-icon>mdi-format-header-2</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('heading', { level: 3 }) ? 'primary' : undefined"
          title="Heading 3"
          @click="editor?.chain().focus().toggleHeading({ level: 3 }).run()"
        >
          <v-icon>mdi-format-header-3</v-icon>
        </v-btn>
      </v-btn-group>

      <v-divider vertical class="mx-1" />

      <v-btn-group density="compact" variant="text" divided>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('bulletList') ? 'primary' : undefined"
          title="Bullet list"
          @click="editor?.chain().focus().toggleBulletList().run()"
        >
          <v-icon>mdi-format-list-bulleted</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('orderedList') ? 'primary' : undefined"
          title="Numbered list"
          @click="editor?.chain().focus().toggleOrderedList().run()"
        >
          <v-icon>mdi-format-list-numbered</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :color="editor?.isActive('blockquote') ? 'primary' : undefined"
          title="Blockquote"
          @click="editor?.chain().focus().toggleBlockquote().run()"
        >
          <v-icon>mdi-format-quote-close</v-icon>
        </v-btn>
      </v-btn-group>

      <v-divider vertical class="mx-1" />

      <v-btn-group density="compact" variant="text" divided>
        <v-btn
          icon
          size="small"
          :disabled="!editor?.can().undo()"
          title="Undo (Ctrl+Z)"
          @click="editor?.chain().focus().undo().run()"
        >
          <v-icon>mdi-undo</v-icon>
        </v-btn>
        <v-btn
          icon
          size="small"
          :disabled="!editor?.can().redo()"
          title="Redo (Ctrl+Shift+Z)"
          @click="editor?.chain().focus().redo().run()"
        >
          <v-icon>mdi-redo</v-icon>
        </v-btn>
      </v-btn-group>

      <v-spacer />

      <span v-if="saving" class="text-caption text-medium-emphasis mr-2">Saving…</span>
      <span v-else-if="savedAt" class="text-caption text-medium-emphasis mr-2">Saved {{ savedAt }}</span>
    </div>

    <!-- Editor area -->
    <editor-content :editor="editor" class="tiptap-content" />
  </div>
</template>

<script setup>
import { onBeforeUnmount, watch } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: 'Start taking notes…' },
  saving: { type: Boolean, default: false },
  savedAt: { type: String, default: null },
})

const emit = defineEmits(['update:modelValue', 'save'])

const editor = useEditor({
  content: props.modelValue || '',
  extensions: [
    StarterKit,
    Placeholder.configure({ placeholder: props.placeholder }),
  ],
  onUpdate({ editor }) {
    emit('update:modelValue', editor.getHTML())
  },
  onBlur() {
    emit('save')
  },
})

// Keep editor in sync if modelValue changes externally (e.g. on fetch)
watch(
  () => props.modelValue,
  (val) => {
    if (editor.value && editor.value.getHTML() !== val) {
      editor.value.commands.setContent(val || '', false)
    }
  },
)

onBeforeUnmount(() => {
  editor.value?.destroy()
})

defineExpose({ editor })
</script>

<style>
.tiptap-wrapper {
  border: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  border-radius: 4px;
  transition: border-color 0.15s;
}

.tiptap-wrapper--focused {
  border-color: rgb(var(--v-theme-primary));
}

.tiptap-toolbar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  padding: 4px 8px;
  border-bottom: 1px solid rgba(var(--v-border-color), var(--v-border-opacity));
  gap: 2px;
}

.tiptap-content {
  padding: 12px 16px;
  min-height: 200px;
  cursor: text;
}

.tiptap-content .tiptap {
  outline: none;
  min-height: 180px;
}

/* Prose styles */
.tiptap-content .tiptap p { margin-bottom: 0.5em; }
.tiptap-content .tiptap p:last-child { margin-bottom: 0; }
.tiptap-content .tiptap h2 { font-size: 1.25rem; font-weight: 600; margin: 1em 0 0.4em; }
.tiptap-content .tiptap h3 { font-size: 1.05rem; font-weight: 600; margin: 0.8em 0 0.3em; }
.tiptap-content .tiptap ul,
.tiptap-content .tiptap ol { padding-left: 1.4em; margin-bottom: 0.5em; }
.tiptap-content .tiptap li { margin-bottom: 0.2em; }
.tiptap-content .tiptap blockquote {
  border-left: 3px solid rgba(var(--v-border-color), 0.6);
  padding-left: 1em;
  margin: 0.5em 0;
  color: rgba(var(--v-theme-on-surface), 0.6);
}
.tiptap-content .tiptap strong { font-weight: 700; }
.tiptap-content .tiptap em { font-style: italic; }
.tiptap-content .tiptap s { text-decoration: line-through; }

/* Placeholder */
.tiptap-content .tiptap p.is-editor-empty:first-child::before {
  content: attr(data-placeholder);
  float: left;
  color: rgba(var(--v-theme-on-surface), 0.38);
  pointer-events: none;
  height: 0;
}
</style>
