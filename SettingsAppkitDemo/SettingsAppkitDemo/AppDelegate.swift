import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.regular)
        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }

        return true
    }

    private func showMainWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let viewController = ViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "SettingsAppkitDemo"
        window.setContentSize(NSSize(width: 720, height: 560))
        window.minSize = NSSize(width: 680, height: 480)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
        window.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async {
            self.positionTrafficLightButtons(in: window)
        }
    }

    private func positionTrafficLightButtons(in window: NSWindow) {
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

        for buttonType in buttons {
            guard let button = window.standardWindowButton(buttonType) else {
                continue
            }

            var frame = button.frame
            frame.origin.x += 22
            frame.origin.y -= 10
            button.frame = frame
        }
    }
}
