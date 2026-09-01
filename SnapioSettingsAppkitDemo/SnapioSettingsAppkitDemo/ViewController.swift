//
//  ViewController.swift
//  SnapioSettingsAppkitDemo
//
//  Created by wangjie on 2026/9/1.
//

import Cocoa

final class ViewController: NSViewController, SettingsViewDelegate {
    private let settingsView = SettingsView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        view = settingsView
        settingsView.delegate = self
        settingsView.render(Self.previewState)
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

}
