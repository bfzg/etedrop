import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { SharePageView } from './pages/SharePageView'

/** 开发时访问 /share 或根路径时显示说明，避免空白页 */
function DevFallback() {
  const demoUrl = '/share/demo/000000'
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-slate-50">
      <div className="max-w-md text-center space-y-4">
        <h1 className="text-xl font-semibold text-slate-800">Eddy 分享页</h1>
        <p className="text-sm text-slate-600">
          请使用完整分享链接：<code className="bg-slate-200 px-1 rounded">/share/:deviceId/:shareCode</code>
        </p>
        <p className="text-sm text-slate-500">
          开发调试可访问：
        </p>
        <a
          href={demoUrl}
          className="inline-block py-2 px-4 rounded-lg bg-indigo-600 text-white text-sm font-medium hover:opacity-90"
        >
          {demoUrl}
        </a>
      </div>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter basename="/share">
      <Routes>
        <Route path="/:deviceId/:shareCode" element={<SharePageView />} />
        <Route path="/" element={<DevFallback />} />
      </Routes>
    </BrowserRouter>
  )
}
