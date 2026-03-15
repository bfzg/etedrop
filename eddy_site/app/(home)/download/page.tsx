import Link from 'next/link';

export default function DownloadPage() {
  return (
    <main className="flex flex-col min-h-screen bg-white text-gray-900">
      <div className="py-24 px-6 text-center">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl mb-6">
          下载 Eddy
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto mb-16">
          选择适合你设备的版本，开始体验极速、安全的私有云传输。
        </p>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          {/* Windows Download */}
          <div className="bg-gray-50 p-10 rounded-2xl border border-gray-100 hover:shadow-lg transition-shadow">
            <div className="w-16 h-16 bg-blue-100 rounded-xl flex items-center justify-center mx-auto mb-6 text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
            </div>
            <h2 className="text-2xl font-bold mb-2">Windows</h2>
            <p className="text-gray-500 mb-8">支持 Windows 10/11 (64位)</p>
            <button className="w-full py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors">
              下载 Windows 版
            </button>
            <p className="text-sm text-gray-400 mt-4">版本 v1.0.0 | 大小 85MB</p>
          </div>

          {/* macOS Download */}
          <div className="bg-gray-50 p-10 rounded-2xl border border-gray-100 hover:shadow-lg transition-shadow">
            <div className="w-16 h-16 bg-gray-200 rounded-xl flex items-center justify-center mx-auto mb-6 text-gray-700">
              <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 19c-4.418 0-8-3.582-8-8s3.582-8 8-8 8 3.582 8 8-3.582 8-8 8z"/><path d="M12 3v16"/></svg>
            </div>
            <h2 className="text-2xl font-bold mb-2">macOS</h2>
            <p className="text-gray-500 mb-8">支持 macOS 11.0+ (Intel & Apple Silicon)</p>
            <button className="w-full py-3 bg-gray-900 text-white rounded-lg font-medium hover:bg-gray-800 transition-colors">
              下载 macOS 版
            </button>
            <p className="text-sm text-gray-400 mt-4">版本 v1.0.0 | 大小 92MB</p>
          </div>
        </div>

        <div className="mt-20 max-w-3xl mx-auto text-left">
          <h3 className="text-2xl font-bold mb-6 text-center">常见问题</h3>
          <div className="space-y-6">
            <div className="border-b border-gray-100 pb-4">
              <h4 className="font-bold mb-2">移动端如何使用？</h4>
              <p className="text-gray-600">
                Eddy 移动端采用 PWA 技术，无需下载安装包。只需在手机浏览器中访问你的分享链接或 Eddy 网页版，即可添加到主屏幕像原生 App 一样使用。
              </p>
            </div>
            <div className="border-b border-gray-100 pb-4">
              <h4 className="font-bold mb-2">Linux 版本支持吗？</h4>
              <p className="text-gray-600">
                Linux 版本正在开发中，敬请期待。目前你可以通过 Docker 部署服务端或使用网页版客户端。
              </p>
            </div>
            <div className="pb-4">
              <h4 className="font-bold mb-2">安装遇到问题？</h4>
              <p className="text-gray-600">
                请查看 <Link href="/docs" className="text-blue-600 hover:underline">帮助文档</Link> 或联系我们的技术支持。
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}