import Link from 'next/link';
import Image from 'next/image';

export default function Footer() {
  return (
    <footer className="bg-slate-900 text-slate-400 py-12 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-6">
        <div className="flex items-center gap-3">
          <Image src="/app_icon.png" alt="Eddy Logo" width={32} height={32} className="rounded-lg grayscale brightness-200" />
          <span className="text-xl font-bold text-white tracking-tight">Eddy</span>
        </div>
        <p>© {new Date().getFullYear()} Eddy. All rights reserved.</p>
        <div className="flex gap-6">
          <Link href="/docs" className="hover:text-white transition-colors">文档</Link>
          <Link href="/privacy" className="hover:text-white transition-colors">隐私政策</Link>
          <Link href="/terms" className="hover:text-white transition-colors">服务条款</Link>
        </div>
      </div>
    </footer>
  );
}
