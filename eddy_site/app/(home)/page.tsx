import Link from 'next/link';

export default function HomePage() {
  return (
    <main className="flex flex-col min-h-screen bg-white text-gray-900">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center px-6 py-24 text-center max-w-5xl mx-auto">
        <h1 className="text-5xl font-bold tracking-tight sm:text-6xl mb-6">
          Eddy: 你的私人云端与极速分享工具
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mb-10 leading-relaxed">
          无需上传云端，直接从你的电脑分享文件给任何人。基于 WebRTC 技术，安全、快速、无大小限制。
          让你的电脑瞬间变身私人网盘，随时随地访问家中文件。
        </p>
        <div className="flex gap-4">
          <Link
            href="/download"
            className="px-8 py-3 bg-black text-white rounded-full font-medium hover:bg-gray-800 transition-colors"
          >
            立即下载
          </Link>
          <Link
            href="/docs"
            className="px-8 py-3 border border-gray-300 rounded-full font-medium hover:bg-gray-50 transition-colors"
          >
            查看文档
          </Link>
        </div>
      </section>

      {/* Product Image Placeholder */}
      <section className="w-full max-w-6xl mx-auto px-6 mb-24">
        <div className="aspect-video bg-gray-100 rounded-2xl border border-gray-200 flex items-center justify-center shadow-sm">
          <span className="text-gray-400 text-xl font-medium">产品效果图展示区域</span>
        </div>
      </section>

      {/* Key Features */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto px-6">
          <h2 className="text-3xl font-bold text-center mb-16">核心功能与优势</h2>
          <div className="grid md:grid-cols-3 gap-10">
            {/* Feature 1 */}
            <div className="bg-white p-8 rounded-xl shadow-sm border border-gray-100">
              <div className="w-12 h-12 bg-blue-50 rounded-lg flex items-center justify-center mb-6 text-blue-600">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
              </div>
              <h3 className="text-xl font-bold mb-3">极速 P2P 传输</h3>
              <p className="text-gray-600 leading-relaxed">
                基于 WebRTC 技术，文件直接从发送端传输到接收端，不经过第三方服务器存储，速度取决于你的带宽上限。
              </p>
            </div>

            {/* Feature 2 */}
            <div className="bg-white p-8 rounded-xl shadow-sm border border-gray-100">
              <div className="w-12 h-12 bg-green-50 rounded-lg flex items-center justify-center mb-6 text-green-600">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              </div>
              <h3 className="text-xl font-bold mb-3">安全隐私保护</h3>
              <p className="text-gray-600 leading-relaxed">
                端到端加密传输，数据完全掌握在自己手中。无需担心文件被云端泄露或审查，真正属于你的私有空间。
              </p>
            </div>

            {/* Feature 3 */}
            <div className="bg-white p-8 rounded-xl shadow-sm border border-gray-100">
              <div className="w-12 h-12 bg-purple-50 rounded-lg flex items-center justify-center mb-6 text-purple-600">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" x2="22" y1="12" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
              </div>
              <h3 className="text-xl font-bold mb-3">无限大小分享</h3>
              <p className="text-gray-600 leading-relaxed">
                不再受限于邮件附件或网盘的空间限制。无论是 4K 视频还是整个项目文件夹，只要你硬盘装得下，就能分享。
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Use Cases / Problems Solved */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6">
          <h2 className="text-3xl font-bold text-center mb-16">解决什么问题？</h2>
          <div className="space-y-12">
            <div className="flex flex-col md:flex-row gap-8 items-start">
              <div className="flex-1">
                <h3 className="text-xl font-bold mb-2">不想上传文件到公共网盘？</h3>
                <p className="text-gray-600">
                  公共网盘限速、审查内容、担心隐私泄露？Eddy 让你的电脑直接成为服务器，文件只在你的设备间流转。
                </p>
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold mb-2">需要远程访问家中电脑文件？</h3>
                <p className="text-gray-600">
                  出门在外突然需要家中电脑里的重要资料？通过 Eddy，你可以随时随地安全访问家中电脑的指定目录。
                </p>
              </div>
            </div>
            <div className="flex flex-col md:flex-row gap-8 items-start">
              <div className="flex-1">
                <h3 className="text-xl font-bold mb-2">大文件传输困难？</h3>
                <p className="text-gray-600">
                  几十 GB 的视频素材传输给同事太慢？Eddy 利用 P2P 技术点对点直传，跑满你的上行带宽。
                </p>
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold mb-2">跨平台文件互传？</h3>
                <p className="text-gray-600">
                  手机传电脑、Mac 传 Windows 很麻烦？Eddy 支持全平台，浏览器即可访问，无需接收方安装客户端。
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How it Works */}
      <section className="py-20 bg-gray-900 text-white">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <h2 className="text-3xl font-bold mb-16">简单三步，开始使用</h2>
          <div className="grid md:grid-cols-3 gap-12">
            <div>
              <div className="text-6xl font-bold text-gray-700 mb-6">1</div>
              <h3 className="text-xl font-bold mb-4">下载并安装</h3>
              <p className="text-gray-400">
                在你的 Windows 或 Mac 电脑上安装 Eddy 客户端，并登录账号。
              </p>
            </div>
            <div>
              <div className="text-6xl font-bold text-gray-700 mb-6">2</div>
              <h3 className="text-xl font-bold mb-4">选择共享目录</h3>
              <p className="text-gray-400">
                指定你想要分享或远程访问的文件夹，Eddy 会自动生成访问链接。
              </p>
            </div>
            <div>
              <div className="text-6xl font-bold text-gray-700 mb-6">3</div>
              <h3 className="text-xl font-bold mb-4">即刻分享与访问</h3>
              <p className="text-gray-400">
                将链接发送给朋友，或在其他设备上直接访问，畅享极速传输体验。
              </p>
            </div>
          </div>
          <div className="mt-16">
            <Link
              href="/download"
              className="px-10 py-4 bg-white text-black rounded-full font-bold hover:bg-gray-200 transition-colors text-lg"
            >
              免费下载体验
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}