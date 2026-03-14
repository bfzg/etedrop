import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// 红黄绿按钮组缩放比例，缩小后整体更紧凑
  private let kTrafficLightScale: CGFloat = 0.90

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // 等 window_manager 等插件配置完标题栏后再缩小按钮组
    DispatchQueue.main.async { [weak self] in
      self?.applyTrafficLightScale()
    }
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResizeNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      self?.applyTrafficLightScale()
    }
  }

  private func applyTrafficLightScale() {
    guard let closeButton = standardWindowButton(.closeButton) else { return }
    guard let container = closeButton.superview else { return }
    // 三个按钮在同一父视图内，对父视图做缩放，使红黄绿整体更窄
    container.wantsLayer = true
    container.layer?.setAffineTransform(CGAffineTransform(scaleX: kTrafficLightScale, y: kTrafficLightScale))
  }
}
