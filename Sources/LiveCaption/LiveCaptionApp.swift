import AppKit
import SwiftUI

@main
struct LiveCaptionApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 760, height: 250)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
