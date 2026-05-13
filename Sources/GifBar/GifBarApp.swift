import AppKit
import SwiftUI

@main
@MainActor
final class GifBarApp: NSObject, NSApplicationDelegate {
    private let library = GifLibrary()
    private let appState = GifBarState()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    static func main() {
        let app = NSApplication.shared
        let delegate = GifBarApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.mainMenu = makeMainMenu()
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenuBarItem()
    }

    private func configureMenuBarItem() {
        let rootView = ContentView()
            .environmentObject(library)
            .environmentObject(appState)
            .frame(width: 480, height: 640)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 480, height: 640)
        popover.contentViewController = NSHostingController(rootView: rootView)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "GifBar")
            button.image?.isTemplate = true
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "GifBar"
        }

        self.popover = popover
        self.statusItem = statusItem
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu()
            return
        }

        togglePopover(sender)
    }

    private func showStatusMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()
        let apiKeyItem = NSMenuItem(
            title: "Giphy API Key...",
            action: #selector(openAPIKeySettings(_:)),
            keyEquivalent: ""
        )
        apiKeyItem.target = self
        menu.addItem(apiKeyItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit GifBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
    }

    @objc private func openAPIKeySettings(_ sender: Any?) {
        appState.showsAPIKeySettings = true
        showPopover()
    }

    private func togglePopover(_ sender: Any?) {
        guard let popover else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button, let popover else { return }

        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    private static func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(
            NSMenuItem(
                title: "Quit GifBar",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        return mainMenu
    }
}
