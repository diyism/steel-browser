import { defineConfig } from '@hey-api/client'

export default defineConfig({
  schemaPath: 'http://api:3000/documentation/json',
  outputPath: './src/generated',
  apiPrefix: '/api/v1',
  requestCreateLib: '@hey-api/client-fetch',
  requestCreateMethod: 'createRequest',
})
