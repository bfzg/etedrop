import Cocoa
import FlutterMacOS
import Network

@main
class AppDelegate: FlutterAppDelegate {
  /// 短时 Bonjour 浏览，用于触发 macOS「本地网络」隐私登记与授权弹窗（Sequoia+ 尤其依赖 Network 框架显式访问）。
  /// 与仅声明 Info.plist 相比，否则应用可能不出现在「设置 → 本地网络」列表，UDP 多播/发现会被静默拦截。
  private var localNetworkBrowser: NWBrowser?
  private let localNetworkTriggerQueue = DispatchQueue(
    label: "com.etedrop.app.local-network-trigger",
    qos: .userInitiated
  )

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    beginLocalNetworkAccessTrigger()
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      sender.windows.forEach { window in
        window.makeKeyAndOrderFront(nil)
      }
    }
    sender.activate(ignoringOtherApps: true)
    return true
  }

  private func beginLocalNetworkAccessTrigger() {
    localNetworkBrowser?.cancel()
    let descriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: nil)
    // `_http._tcp` 为基于 TCP 的 Bonjour 服务类型，与 NSBonjourServices 一致。
    let parameters = NWParameters.tcp
    parameters.includePeerToPeer = false

    let browser = NWBrowser(for: descriptor, using: parameters)
    localNetworkBrowser = browser

    browser.stateUpdateHandler = { [weak self] state in
      switch state {
      case .ready:
        NSLog("LAN privacy trigger: NWBrowser ready")
      case .failed(let error):
        NSLog("LAN privacy trigger browser failed: \(error.localizedDescription)")
        self?.localNetworkBrowser?.cancel()
        self?.localNetworkBrowser = nil
      case .waiting(let error):
        NSLog("LAN privacy trigger waiting: \(error.localizedDescription)")
      default:
        break
      }
    }

    browser.browseResultsChangedHandler = { _, _ in
      // 保持浏览活动，便于系统登记本地网络访问意图。
    }

    browser.start(queue: localNetworkTriggerQueue)

    // 自签/未公证包有时较晚才弹出授权；略延长再结束，避免用户来不及点「允许」。
    DispatchQueue.main.asyncAfter(deadline: .now() + 45) { [weak self] in
      self?.localNetworkBrowser?.cancel()
      self?.localNetworkBrowser = nil
    }
  }
}
