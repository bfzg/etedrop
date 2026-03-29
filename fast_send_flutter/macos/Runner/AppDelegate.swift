import Cocoa
import FlutterMacOS
import Network

@main
class AppDelegate: FlutterAppDelegate {
  /// 短时 Bonjour 浏览，用于触发 macOS「本地网络」隐私登记与授权弹窗；仅 plist 时应用常不出现在设置列表且多播可能被静默拦截。
  private var localNetworkBrowser: NWBrowser?

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

  private func beginLocalNetworkAccessTrigger() {
    localNetworkBrowser?.cancel()
    let descriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: nil)
    let parameters = NWParameters()
    parameters.includePeerToPeer = false

    let browser = NWBrowser(for: descriptor, using: parameters)
    localNetworkBrowser = browser

    browser.stateUpdateHandler = { [weak self] state in
      if case .failed(let error) = state {
        NSLog("LAN privacy trigger browser failed: \(error.localizedDescription)")
        self?.localNetworkBrowser?.cancel()
        self?.localNetworkBrowser = nil
      }
    }

    browser.start(queue: .main)

    DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
      self?.localNetworkBrowser?.cancel()
      self?.localNetworkBrowser = nil
    }
  }
}
