export default function Features() {
  return (
    <section id="features" className="py-24 bg-slate-50">
      <div className="max-w-7xl mx-auto px-6">
        <div className="text-center mb-20">
          <h2 className="text-blue-600 font-semibold tracking-wide uppercase mb-3">核心优势</h2>
          <h3 className="text-4xl font-bold text-slate-900">为什么选择 Eddy？</h3>
        </div>
        
        <div className="grid md:grid-cols-3 gap-8">
          {/* Feature 1 */}
          <div className="bg-white p-10 rounded-3xl shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
            <div className="w-14 h-14 bg-blue-100 rounded-2xl flex items-center justify-center mb-8 text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            </div>
            <h4 className="text-2xl font-bold mb-4 text-slate-900">接收方免客户端</h4>
            <p className="text-slate-600 leading-relaxed text-lg">
              分享文件时，对方只需在浏览器中打开链接即可直接下载。无需下载 App，无需注册账号，跨越设备与平台的鸿沟。
            </p>
          </div>

          {/* Feature 2 */}
          <div className="bg-white p-10 rounded-3xl shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
            <div className="w-14 h-14 bg-cyan-100 rounded-2xl flex items-center justify-center mb-8 text-cyan-600">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
            </div>
            <h4 className="text-2xl font-bold mb-4 text-slate-900">P2P 极速直传</h4>
            <p className="text-slate-600 leading-relaxed text-lg">
              文件直接从你的电脑传输到对方设备，不经过任何第三方服务器存储。传输速度仅取决于双方的网络带宽，跑满你的网速。
            </p>
          </div>

          {/* Feature 3 */}
          <div className="bg-white p-10 rounded-3xl shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
            <div className="w-14 h-14 bg-blue-100 rounded-2xl flex items-center justify-center mb-8 text-blue-600">
              <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
            </div>
            <h4 className="text-2xl font-bold mb-4 text-slate-900">变身私人网盘</h4>
            <p className="text-slate-600 leading-relaxed text-lg">
              指定电脑上的文件夹作为存储目录，出门在外也能通过手机或网页随时访问家中电脑的文件。硬盘有多大，网盘就有多大。
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
