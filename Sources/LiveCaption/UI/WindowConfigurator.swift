import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 620, height: 170)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }
}
