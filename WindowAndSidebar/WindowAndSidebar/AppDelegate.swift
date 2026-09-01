//
//  AppDelegate.swift
//  WindowAndSidebar
//
//  Created by Xiang on 9/1/26.
//

import AppKit

@main
enum ApplicationMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browserWindowController: BrowserWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMainMenu()
        let controller = BrowserWindowController()
        browserWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationItem.submenu = applicationMenu
        applicationMenu.addItem(
            withTitle: "About WindowAndSidebar",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(
            withTitle: "Hide WindowAndSidebar",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        applicationMenu.addItem(
            withTitle: "Hide Others",
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h"
        ).keyEquivalentModifierMask = [.command, .option]
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(
            withTitle: "Quit WindowAndSidebar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu
        fileMenu.addItem(
            withTitle: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewItem.submenu = viewMenu
        viewMenu.addItem(
            withTitle: "Toggle Sidebar",
            action: #selector(NSSplitViewController.toggleSidebar(_:)),
            keyEquivalent: "s"
        ).keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(
            withTitle: "Enter Full Screen",
            action: #selector(NSWindow.toggleFullScreen(_:)),
            keyEquivalent: "f"
        ).keyEquivalentModifierMask = [.command, .control]

        let windowItem = NSMenuItem()
        mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu
        windowMenu.addItem(
            withTitle: "Minimize",
            action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m"
        )
        windowMenu.addItem(
            withTitle: "Zoom",
            action: #selector(NSWindow.performZoom(_:)),
            keyEquivalent: ""
        )
        NSApp.windowsMenu = windowMenu
    }
}
