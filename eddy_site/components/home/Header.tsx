import Link from 'next/link';
import Image from 'next/image';

export default function Header() {
  return (
    <header className="w-full py-6 px-6 md:px-12 flex justify-between items-center bg-white/80 backdrop-blur-md sticky top-0 z-50 border-b border-slate-100">
      <div className="flex items-center gap-3">
        <Image src="/app_icon.png" alt="Eddy Logo" width={40} height={40} className="rounded-xl" />
        <span className="text-2xl font-bold text-blue-600 tracking-tight">Eddy</span>
      </div>
      <nav className="hidden md:flex gap-8 text-slate-600 font-medium">
        <a href="#features" className="hover:text-blue-600 transition-colors">核心特性</a>
        <a href="#how-it-works" className="hover:text-blue-600 transition-colors">如何使用</a>
        <a href="#pricing" className="hover:text-blue-600 transition-colors">价格</a>
      </nav>
      <div className="flex gap-4">
        <Link
          href="/docs"
          className="hidden md:inline-flex px-5 py-2 text-blue-600 font-medium hover:bg-blue-50 rounded-full transition-colors"
        >
          查看文档
        </Link>
        <Link
          href="/download"
          className="px-5 py-2 bg-blue-600 text-white rounded-full font-medium hover:bg-blue-700 transition-colors shadow-md shadow-blue-200"
        >
          获取客户端
        </Link>
      </div>
    </header>
  );
}
