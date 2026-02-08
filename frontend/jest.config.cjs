module.exports = {
  testEnvironment: 'jsdom',
  testMatch: ['**/tests/unit/**/*.test.js'],
  testPathIgnorePatterns: ['/node_modules/', 'tests/e2e'],
  transform: {
    '^.+\\.vue$': '@vue/vue3-jest',
    '^.+\\.[jt]sx?$': 'babel-jest'
  },
  moduleFileExtensions: ['js', 'json', 'vue', 'jsx', 'ts', 'tsx'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
    '^vuetify/(.*)$': '<rootDir>/node_modules/vuetify/$1'
  },
  transformIgnorePatterns: [
    'node_modules/(?!vuetify|@vue|vue-router)'
  ],
  setupFilesAfterEnv: ['<rootDir>/tests/unit/setup.js'],
  testEnvironmentOptions: {
    customExportConditions: ['node', 'node-addons']
  },
  collectCoverage: true,
  collectCoverageFrom: ['src/**/*.{js,vue,ts,tsx}'],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html']
}
