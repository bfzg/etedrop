export default function HowItWorks() {
  return (
    <section id="how-it-works" className="py-24 bg-blue-600 text-white relative overflow-hidden">
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden z-0">
        <div className="absolute -top-[20%] -right-[10%] w-[50%] h-[50%] rounded-full bg-blue-500 blur-3xl opacity-50"></div>
        <div className="absolute -bottom-[20%] -left-[10%] w-[50%] h-[50%] rounded-full bg-blue-700 blur-3xl opacity-50"></div>
      </div>
      
      <div className="max-w-7xl mx-auto px-6 relative z-10">
        <div className="text-center mb-20">
          <h2 className="text-4xl font-bold mb-6">简单三步，即刻开启</h2>
          <p className="text-blue-100 text-xl max-w-2xl mx-auto">让文件分享变得前所未有的简单与高效</p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-12 text-center">
          <div className="bg-blue-700/30 backdrop-blur-sm p-8 rounded-3xl border border-blue-500/30">
            <div className="w-16 h-16 bg-white text-blue-600 rounded-2xl flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg">1</div>
            <h3 className="text-2xl font-bold mb-4">安装桌面端</h3>
            <p className="text-blue-100 text-lg">
              在你的电脑上安装 Eddy 客户端，并保持后台运行。你的电脑即刻成为一台强大的私人服务器。
            </p>
          </div>
          <div className="bg-blue-700/30 backdrop-blur-sm p-8 rounded-3xl border border-blue-500/30">
            <div className="w-16 h-16 bg-white text-blue-600 rounded-2xl flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg">2</div>
            <h3 className="text-2xl font-bold mb-4">选择文件或目录</h3>
            <p className="text-blue-100 text-lg">
              选择你想要分享的单个文件，或指定一个文件夹作为你的"云盘"目录，一键生成专属链接。
            </p>
          </div>
          <div className="bg-blue-700/30 backdrop-blur-sm p-8 rounded-3xl border border-blue-500/30">
            <div className="w-16 h-16 bg-white text-blue-600 rounded-2xl flex items-center justify-center text-2xl font-bold mx-auto mb-6 shadow-lg">3</div>
            <h3 className="text-2xl font-bold mb-4">浏览器极速访问</h3>
            <p className="text-blue-100 text-lg">
              将链接发给朋友，他们无需安装任何软件，在手机或电脑浏览器中打开即可直接下载。
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
