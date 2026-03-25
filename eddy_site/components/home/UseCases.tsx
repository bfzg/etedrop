export default function UseCases() {
  return (
    <section className="py-24 bg-white">
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex flex-col md:flex-row items-center gap-16">
          <div className="flex-1">
            <h2 className="text-4xl font-bold text-slate-900 mb-8 leading-tight">
              告别传统网盘的<br/><span className="text-blue-600">限速与繁琐</span>
            </h2>
            <ul className="space-y-8">
              <li className="flex gap-4">
                <div className="mt-1 bg-blue-100 p-2 rounded-full text-blue-600 shrink-0">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                </div>
                <div>
                  <h4 className="text-xl font-bold text-slate-900 mb-2">分享超大文件</h4>
                  <p className="text-slate-600 text-lg">几十GB的视频素材、设计工程文件？直接生成链接发给客户，无需漫长的上传等待。</p>
                </div>
              </li>
              <li className="flex gap-4">
                <div className="mt-1 bg-blue-100 p-2 rounded-full text-blue-600 shrink-0">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                </div>
                <div>
                  <h4 className="text-xl font-bold text-slate-900 mb-2">保护隐私数据</h4>
                  <p className="text-slate-600 text-lg">机密文档不想传到公共云端？端到端加密直传，数据完全掌握在自己手中，拒绝审查与泄露。</p>
                </div>
              </li>
              <li className="flex gap-4">
                <div className="mt-1 bg-blue-100 p-2 rounded-full text-blue-600 shrink-0">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                </div>
                <div>
                  <h4 className="text-xl font-bold text-slate-900 mb-2">跨设备文件互传</h4>
                  <p className="text-slate-600 text-lg">手机传电脑、Mac 传 Windows，不再需要数据线或微信文件传输助手，局域网内秒传。</p>
                </div>
              </li>
            </ul>
          </div>
          <div className="flex-1 w-full">
            <div className="bg-slate-50 p-8 rounded-3xl border border-slate-200 shadow-lg relative">
              <div className="absolute -top-6 -right-6 w-24 h-24 bg-blue-100 rounded-full blur-2xl opacity-60"></div>
              <div className="absolute -bottom-6 -left-6 w-32 h-32 bg-cyan-100 rounded-full blur-2xl opacity-60"></div>
              
              <div className="relative bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
                <div className="flex items-center justify-between mb-6">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center text-blue-600">
                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                    </div>
                    <div>
                      <h5 className="font-bold text-slate-900">项目演示视频.mp4</h5>
                      <p className="text-sm text-slate-500">2.4 GB</p>
                    </div>
                  </div>
                  <span className="px-3 py-1 bg-green-100 text-green-700 text-xs font-bold rounded-full">传输中</span>
                </div>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">速度: 45 MB/s</span>
                    <span className="font-medium text-blue-600">68%</span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-2.5">
                    <div className="bg-blue-600 h-2.5 rounded-full" style={{ width: '68%' }}></div>
                  </div>
                  <div className="text-right text-xs text-slate-400 mt-1">剩余时间: 约 18 秒</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
