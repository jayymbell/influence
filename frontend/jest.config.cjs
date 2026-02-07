module.exports = {
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.vue$': '@vue/vue3-jest',
    '^.+\\.[jt]sx?$': 'babel-jest'
  },
  moduleFileExtensions: ['js', 'json', 'vue', 'jsx', 'ts', 'tsx'],
  collectCoverage: true,
  collectCoverageFrom: ['src/**/*.{js,vue,ts,tsx}'],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html']
}
