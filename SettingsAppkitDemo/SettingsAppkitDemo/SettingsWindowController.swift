import Cocoa

final class SettingsWindowController: NSWindowController {
    private let settingsController = ViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        configureWindow(window)
        window.contentViewController = settingsController
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        guard let window else {
            return
        }

        DispatchQueue.main.async {
            self.positionTrafficLightButtons(in: window)
        }
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "SettingsAppkitDemo"
        window.setContentSize(NSSize(width: 720, height: 560))
        window.minSize = NSSize(width: 680, height: 480)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.center()
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
