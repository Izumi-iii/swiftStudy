import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindowController: SettingsWindowController?

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
        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            return
        }

        let controller = SettingsWindowController()
        settingsWindowController = controller
        controller.showWindow(nil)
    }
}
