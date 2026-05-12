import AppKit
import SwiftUI

@main
@MainActor
final class GifBarApp: NSObject, NSApplicationDelegate {
    private let library = GifLibrary()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var dropPanel: NSPanel?
    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?

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
        configureDropShelf()
        configureDragDetection()
    }

    private func configureMenuBarItem() {
        let rootView = ContentView()
            .environmentObject(library)
            .frame(width: 390, height: 560)

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 390, height: 560)
        popover.contentViewController = NSHostingController(rootView: rootView)

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "play.rectangle.fill", accessibilityDescription: "GifBar")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.toolTip = "GifBar"
        }

        self.popover = popover
        self.statusItem = statusItem
    }

    private func configureDropShelf() {
        let rootView = DropShelfView {
            self.hideDropShelf()
        }
        .environmentObject(library)

        let hostingView = NSHostingView(rootView: rootView)
        let panel = NSPanel(
            contentRect: dropShelfFrame(),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false

        dropPanel = panel
    }

    private func configureDragDetection() {
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            Task { @MainActor in
                self?.updateDropShelfVisibilityForCurrentMouseLocation()
            }
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            Task { @MainActor in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self?.hideDropShelf()
                }
            }
        }
    }

    private func updateDropShelfVisibilityForCurrentMouseLocation() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let mouse = NSEvent.mouseLocation
        let centerX = visibleFrame.midX
        let isNearTopCenter = abs(mouse.x - centerX) < 260 && mouse.y > visibleFrame.maxY - 90

        if isNearTopCenter {
            showDropShelf()
        }
    }

    private func showDropShelf() {
        guard let dropPanel else { return }
        dropPanel.setFrame(dropShelfFrame(), display: true)
        if !dropPanel.isVisible {
            dropPanel.orderFrontRegardless()
        }
    }

    private func hideDropShelf() {
        dropPanel?.orderOut(nil)
    }

    private func dropShelfFrame() -> NSRect {
        let size = NSSize(width: 360, height: 92)
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)
        return NSRect(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.maxY - size.height - 12,
            width: size.width,
            height: size.height
        )
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
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

        return mainMenu
    }
}
