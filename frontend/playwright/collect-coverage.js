const fs = require('fs')
const path = require('path')

async function collectCoverage(page, id) {
  const coverage = await page.evaluate(() => window.__coverage__)
  if (!coverage) return null
  const outDir = path.resolve(process.cwd(), 'coverage', 'playwright')
  fs.mkdirSync(outDir, { recursive: true })
  const filename = path.join(outDir, `coverage-${id || Date.now()}.json`)
  fs.writeFileSync(filename, JSON.stringify(coverage))
  return filename
}

module.exports = { collectCoverage }
