//
//  ViewController.swift
//  SnapioSettingsAppkitDemo
//
//  Created by wangjie on 2026/9/1.
//

import Cocoa

final class ViewController: NSViewController, SettingsViewDelegate {
    private static let preferredWindowContentSize = NSSize(width: 760, height: 540)

    private let splitViewController = NSSplitViewController()
    private let sidebarViewController = SettingsSidebarViewController()
    private let detailViewController = NSViewController()
    private let settingsView = SettingsView(frame: .zero)
    private var didSetInitialWindowSize = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSplitViewController()
        view = splitViewController.view
        addChild(splitViewController)

        settingsView.delegate = self
        settingsView.render(Self.previewState)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        configureWindow()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    func settingsView(
        _ view: SettingsView,
        didRecord shortcut: KeyboardShortcut
    ) {
        settingsView.render(Self.previewState(activeShortcut: shortcut))
    }

    func settingsView(
        _ view: SettingsView,
        didRecordAnnotationShortcut shortcut: KeyboardShortcut,
        for action: AnnotationShortcutAction
    ) {}

    func settingsViewDidRequestDirectory(_ view: SettingsView) {}

    func settingsViewDidRequestDirectoryValidation(_ view: SettingsView) {}

    func settingsViewDidRequestDirectoryReveal(_ view: SettingsView) {}

    func settingsViewDidRequestPermissionGrant(_ view: SettingsView) {}

    func settingsView(
        _ view: SettingsView,
        didChangeOutputOptions outputOptions: OutputOptions
    ) {
        settingsView.render(Self.previewState(outputOptions: outputOptions))
    }

    func settingsView(
        _ view: SettingsView,
        didRecordCurrentDisplayShortcut shortcut: KeyboardShortcut
    ) {
        settingsView.render(Self.previewState(currentDisplayShortcut: shortcut))
    }

    func settingsView(
        _ view: SettingsView,
        didChangeShortcutRecording isRecording: Bool
    ) {}

    private static let previewState = previewState()

    private static func previewState(
        activeShortcut: KeyboardShortcut = KeyboardShortcut(
            keyCode: 18,
            modifiers: .command
        ),
        currentDisplayShortcut: KeyboardShortcut = KeyboardShortcut(
            keyCode: 19,
            modifiers: .command
        ),
        outputOptions: OutputOptions = .default
    ) -> SettingsViewState {
        SettingsViewState(
            activeShortcut: activeShortcut,
            currentDisplayShortcut: currentDisplayShortcut,
            shortcutError: nil,
            directoryStatus: .valid(
                DirectoryReference(
                    bookmarkData: Data(),
                    displayPath: "/Users/wangjie/Desktop"
                )
            ),
            settingsError: nil,
            annotationShortcuts: .default,
            permissionSnapshot: PermissionSnapshot(screenCapture: .granted),
            isCheckingPermissions: false,
            outputOptions: outputOptions
        )
    }

    private func configureWindow() {
        guard let window = view.window else { return }

        window.title = "Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.minSize = NSSize(width: 740, height: 520)

        if !didSetInitialWindowSize {
            window.setContentSize(Self.preferredWindowContentSize)
            didSetInitialWindowSize = true
        }

        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified
    }

    private func configureSplitViewController() {
        sidebarViewController.selectionHandler = { [weak self] page in
            self?.settingsView.selectPage(page)
        }

        detailViewController.view = settingsView

        let sidebarItem = NSSplitViewItem(
            sidebarWithViewController: sidebarViewController
        )
        sidebarItem.minimumThickness = 236
        sidebarItem.maximumThickness = 260
        sidebarItem.canCollapse = false

        let detailItem = NSSplitViewItem(viewController: detailViewController)
        detailItem.minimumThickness = 500

        splitViewController.splitView.isVertical = true
        splitViewController.splitView.dividerStyle = .thin
        splitViewController.addSplitViewItem(sidebarItem)
        splitViewController.addSplitViewItem(detailItem)
    }

}

extension ViewController: NSToolbarDelegate {
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        nil
    }

    func toolbarAllowedItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarDefaultItemIdentifiers(
        _ toolbar: NSToolbar
    ) -> [NSToolbarItem.Identifier] {
        [
            .sidebarTrackingSeparator,
            .flexibleSpace
        ]
    }

}
