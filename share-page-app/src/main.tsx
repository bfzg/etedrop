import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './lib/streamSaverConfig'
import './output.css'
import './i18n'
import App from './App'
import { cleanupStaleOpfsDownloads } from './utils/shareDownloadStorage'

void cleanupStaleOpfsDownloads()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
