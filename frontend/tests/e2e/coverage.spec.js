import { test, expect } from '@playwright/test'
import { collectCoverage } from '../../playwright/collect-coverage.js'

test('app loads and collects coverage', async ({ page }, testInfo) => {
  await page.goto('/')
  // Check that the main anchor exists (App.vue toolbar title)
  const title = page.locator('a').first()
  await expect(title).toContainText('My App')

  // collect coverage from the window.__coverage__ created by the instrumented build
  const out = await collectCoverage(page, testInfo.title.replace(/\s+/g, '-'))
  expect(out).not.toBeNull()
})
