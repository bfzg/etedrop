import Link from 'next/link';

export default function Pricing() {
  return (
    <section id="pricing" className="py-24 bg-slate-50">
      <div className="max-w-4xl mx-auto px-6 text-center">
        <h2 className="text-blue-600 font-semibold tracking-wide uppercase mb-3">简单透明的定价</h2>
        <h3 className="text-4xl font-bold text-slate-900 mb-6">一杯咖啡的价格，畅享一整年</h3>
        <p className="text-xl text-slate-600 mb-16">没有复杂的订阅层级，没有隐藏费用，一次付费，解锁全部功能。</p>
        
        <div className="bg-white rounded-3xl shadow-xl border border-blue-100 overflow-hidden max-w-lg mx-auto relative">
          <div className="absolute top-0 left-0 w-full h-2 bg-blue-600"></div>
          <div className="p-10">
            <h4 className="text-2xl font-bold text-slate-900 mb-2">Eddy Pro</h4>
            <p className="text-slate-500 mb-6">适合所有需要高效传输文件的用户</p>
            <div className="flex items-baseline justify-center gap-1 mb-8">
              <span className="text-5xl font-extrabold text-slate-900">$10</span>
              <span className="text-xl text-slate-500 font-medium">/ 年</span>
            </div>
            
            <ul className="space-y-4 text-left mb-10">
              <li className="flex items-center gap-3 text-slate-700">
                <svg className="text-blue-600 shrink-0" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>无限次文件分享</span>
              </li>
              <li className="flex items-center gap-3 text-slate-700">
                <svg className="text-blue-600 shrink-0" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>无文件大小限制</span>
              </li>
              <li className="flex items-center gap-3 text-slate-700">
                <svg className="text-blue-600 shrink-0" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>接收方免安装客户端</span>
              </li>
              <li className="flex items-center gap-3 text-slate-700">
                <svg className="text-blue-600 shrink-0" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>端到端加密传输</span>
              </li>
              <li className="flex items-center gap-3 text-slate-700">
                <svg className="text-blue-600 shrink-0" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                <span>多设备远程访问</span>
              </li>
            </ul>
            
            <Link
              href="/download"
              className="block w-full py-4 bg-blue-600 text-white rounded-xl font-bold text-lg hover:bg-blue-700 transition-colors shadow-md shadow-blue-200"
            >
              立即开始使用
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
