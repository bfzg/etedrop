import Cocoa
import FlutterMacOS
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
  /// 红黄绿按钮组缩放比例，缩小后整体更紧凑
  private let kTrafficLightScale: CGFloat = 0.90

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // launch_at_startup：pub 包在 macOS 侧无自动注册，需与 LaunchAtLogin SPM 配套（见 Runner.xcodeproj）
    FlutterMethodChannel(
      name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LaunchAtLogin.isEnabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any],
           let enabled = arguments["setEnabledValue"] as? Bool {
          LaunchAtLogin.isEnabled = enabled
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

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
