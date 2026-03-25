export default function ProductShowcase() {
  return (
    <section className="w-full max-w-6xl mx-auto px-6 mb-32 relative z-10">
      <div className="aspect-[16/10] bg-slate-50 rounded-3xl border border-slate-200 shadow-2xl shadow-slate-200/50 flex items-center justify-center overflow-hidden relative">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 to-slate-50"></div>
        {/* Mock UI */}
        <div className="absolute inset-4 bg-white rounded-2xl shadow-sm border border-slate-100 flex flex-col overflow-hidden">
          <div className="h-12 border-b border-slate-100 flex items-center px-4 gap-2 bg-slate-50/50">
            <div className="w-3 h-3 rounded-full bg-red-400"></div>
            <div className="w-3 h-3 rounded-full bg-amber-400"></div>
            <div className="w-3 h-3 rounded-full bg-green-400"></div>
          </div>
          <div className="flex-1 flex items-center justify-center text-slate-400 font-medium">
            Eddy 桌面端界面展示区域
          </div>
        </div>
      </div>
    </section>
  );
}
