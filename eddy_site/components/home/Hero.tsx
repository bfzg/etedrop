import Link from 'next/link';

export default function Hero() {
  return (
    <section className="relative flex flex-col items-center justify-center px-6 py-24 md:py-32 text-center max-w-6xl mx-auto overflow-hidden">
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full max-w-3xl -z-10 bg-blue-50 blur-3xl rounded-full opacity-50"></div>
      
      <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-50 text-blue-600 font-medium text-sm mb-8 border border-blue-100">
        <span className="relative flex h-2.5 w-2.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-blue-500"></span>
        </span>
        全新一代 P2P 文件传输方案
      </div>
      
      <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-8 text-slate-900 leading-tight">
        将你的电脑变成 <br className="hidden md:block" />
        <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-cyan-500">
          极速私人网盘
        </span>
      </h1>
      
      <p className="text-xl text-slate-600 max-w-3xl mb-12 leading-relaxed">
        无需上传云端，直接从你的电脑分享文件给任何人。
        <strong className="text-blue-600 font-semibold">接收方免安装客户端</strong>，浏览器打开链接即可极速下载。
        安全、私密、无文件大小限制。
      </p>
      
      <div className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
        <Link
          href="/download"
          className="px-8 py-4 bg-blue-600 text-white rounded-full font-bold text-lg hover:bg-blue-700 transition-all shadow-lg shadow-blue-600/30 hover:shadow-blue-600/50 hover:-translate-y-1 flex items-center justify-center gap-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          下载桌面端 (Windows/Mac)
        </Link>
        <Link
          href="#how-it-works"
          className="px-8 py-4 bg-white text-slate-700 border border-slate-200 rounded-full font-bold text-lg hover:bg-slate-50 hover:border-slate-300 transition-all flex items-center justify-center gap-2"
        >
          了解工作原理
        </Link>
      </div>
      <p className="mt-6 text-sm text-slate-500">仅需发送方安装桌面端，接收方使用浏览器即可</p>
    </section>
  );
}
