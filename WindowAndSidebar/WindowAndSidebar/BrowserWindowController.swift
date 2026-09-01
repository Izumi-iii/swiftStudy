import AppKit

final class BrowserWindowController: NSWindowController, NSToolbarDelegate, NSSearchFieldDelegate {
    private enum ToolbarItem {
        static let navigation = NSToolbarItem.Identifier("navigation")
        static let title = NSToolbarItem.Identifier("title")
        static let sort = NSToolbarItem.Identifier("sort")
        static let airDrop = NSToolbarItem.Identifier("airDrop")
        static let view = NSToolbarItem.Identifier("view")
        static let actions = NSToolbarItem.Identifier("actions")
        static let search = NSToolbarItem.Identifier("search")
    }

    private let browserController = BrowserSplitViewController()
    private weak var backButton: NSButton?
    private weak var forwardButton: NSButton?
    private weak var titleLabel: NSTextField?
    private weak var searchField: NSSearchField?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1220, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        configureWindow(window)
        browserController.delegate = self
        window.contentViewController = browserController
        configureToolbar(for: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureWindow(_ window: NSWindow) {
        window.title = "Finder"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 780, height: 500)
        window.setFrameAutosaveName("BrowserWindow")
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .windowBackgroundColor
        window.center()
    }

    private func configureToolbar(for window: NSWindow) {
        let toolbar = NSToolbar(identifier: "BrowserToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .sidebarTrackingSeparator,
            ToolbarItem.navigation,
            ToolbarItem.title,
            .flexibleSpace,
            ToolbarItem.sort,
            ToolbarItem.airDrop,
            ToolbarItem.view,
            ToolbarItem.actions,
            ToolbarItem.search
        ]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier identifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch identifier {
        case ToolbarItem.navigation:
            navigationToolbarItem(identifier: identifier)
        case ToolbarItem.title:
            titleToolbarItem(identifier: identifier)
        case ToolbarItem.sort:
            menuToolbarItem(identifier: identifier, symbol: "list.bullet", label: "Sort", menu: makeSortMenu())
        case ToolbarItem.airDrop:
            buttonToolbarItem(identifier: identifier, symbol: "airplayaudio", label: "AirDrop", action: #selector(showAirDrop))
        case ToolbarItem.view:
            menuToolbarItem(identifier: identifier, symbol: "rectangle.grid.1x2", label: "View", menu: makeViewMenu())
        case ToolbarItem.actions:
            actionsToolbarItem(identifier: identifier)
        case ToolbarItem.search:
            searchToolbarItem(identifier: identifier)
        default:
            nil
        }
    }

    private func navigationToolbarItem(identifier: NSToolbarItem.Identifier) -> NSToolbarItem {
        let back = NSButton(
            image: NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Back")!,
            target: self,
            action: #selector(goBack)
        )
        let forward = NSButton(
            image: NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Forward")!,
            target: self,
            action: #selector(goForward)
        )
        [back, forward].forEach {
            $0.bezelStyle = .texturedRounded
            $0.imageScaling = .scaleProportionallyDown
            $0.setButtonType(.momentaryPushIn)
        }

        let stack = NSStackView(views: [back, forward])
        stack.orientation = .horizontal
        stack.spacing = -1
        stack.setHuggingPriority(.required, for: .horizontal)
        stack.frame.size = NSSize(width: 72, height: 32)

        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "Navigation"
        item.view = stack

        backButton = back
        forwardButton = forward
        updateNavigationButtons()
        return item
    }

    private func titleToolbarItem(identifier: NSToolbarItem.Identifier) -> NSToolbarItem {
        let label = NSTextField(labelWithString: browserController.displayedTitle)
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.frame.size = NSSize(width: 160, height: 24)

        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "Location"
        item.view = label
        titleLabel = label
        return item
    }

    private func buttonToolbarItem(
        identifier: NSToolbarItem.Identifier,
        symbol: String,
        label: String,
        action: Selector
    ) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        item.target = self
        item.action = action
        return item
    }

    private func menuToolbarItem(
        identifier: NSToolbarItem.Identifier,
        symbol: String,
        label: String,
        menu: NSMenu
    ) -> NSToolbarItem {
        let item = NSMenuToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        item.menu = menu
        item.showsIndicator = true
        return item
    }

    private func actionsToolbarItem(identifier: NSToolbarItem.Identifier) -> NSToolbarItem {
        let share = NSButton(
            image: NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Share")!,
            target: self,
            action: #selector(shareSelection)
        )
        let tags = NSButton(
            image: NSImage(systemSymbolName: "tag", accessibilityDescription: "Tags")!,
            target: self,
            action: #selector(showTags)
        )
        let more = NSButton(
            image: NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "More")!,
            target: self,
            action: #selector(showMoreMenu(_:))
        )
        [share, tags, more].forEach {
            $0.bezelStyle = .texturedRounded
            $0.imageScaling = .scaleProportionallyDown
        }

        let stack = NSStackView(views: [share, tags, more])
        stack.orientation = .horizontal
        stack.spacing = 2
        stack.frame.size = NSSize(width: 112, height: 32)

        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "Actions"
        item.view = stack
        return item
    }

    private func searchToolbarItem(identifier: NSToolbarItem.Identifier) -> NSToolbarItem {
        let search = NSSearchField(frame: NSRect(x: 0, y: 0, width: 180, height: 28))
        search.placeholderString = "Search"
        search.delegate = self
        search.sendsSearchStringImmediately = true

        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "Search"
        item.view = search
        searchField = search
        return item
    }

    private func makeSortMenu() -> NSMenu {
        let menu = NSMenu(title: "Sort")
        let entries: [(String, FileSortKey)] = [
            ("Name", .name),
            ("Date Modified", .dateModified),
            ("Size", .size),
            ("Kind", .kind)
        ]
        entries.forEach { title, key in
            let item = NSMenuItem(title: title, action: #selector(changeSort(_:)), keyEquivalent: "")
            item.target = self
            item.tag = key.rawValue
            menu.addItem(item)
        }
        return menu
    }

    private func makeViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")
        let list = NSMenuItem(title: "as List", action: nil, keyEquivalent: "")
        list.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: nil)
        list.state = .on
        menu.addItem(list)
        return menu
    }

    @objc private func goBack() {
        browserController.goBack()
    }

    @objc private func goForward() {
        browserController.goForward()
    }

    @objc private func changeSort(_ sender: NSMenuItem) {
        guard let key = FileSortKey(rawValue: sender.tag) else { return }
        browserController.sort(by: key)
    }

    @objc private func showAirDrop() {
        browserController.selectSidebarItem(named: "AirDrop")
    }

    @objc private func shareSelection() {
        guard let url = browserController.selectedURL,
              let view = window?.contentView else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }

    @objc private func showTags() {
        NSSound.beep()
    }

    @objc private func showMoreMenu(_ sender: NSButton) {
        let menu = NSMenu(title: "More")
        menu.addItem(withTitle: "New Folder", action: #selector(createFolder), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Show in Finder", action: #selector(revealSelection), keyEquivalent: "")
        menu.items.forEach { $0.target = self }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY + 4), in: sender)
    }

    @objc private func createFolder() {
        browserController.createFolder()
    }

    @objc private func revealSelection() {
        guard let url = browserController.selectedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func controlTextDidChange(_ obj: Notification) {
        browserController.filter(with: searchField?.stringValue ?? "")
    }

    private func updateNavigationButtons() {
        backButton?.isEnabled = browserController.canGoBack
        forwardButton?.isEnabled = browserController.canGoForward
    }
}

extension BrowserWindowController: BrowserSplitViewControllerDelegate {
    func browserSplitViewControllerDidChangeLocation(_ controller: BrowserSplitViewController) {
        titleLabel?.stringValue = controller.displayedTitle
        searchField?.stringValue = ""
        updateNavigationButtons()
    }
}
