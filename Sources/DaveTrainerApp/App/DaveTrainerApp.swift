import AppKit
import Darwin
import SwiftUI

@main
struct DaveTheTrainerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: AppStore

    init() {
        RuntimeCommandLineTool.runIfRequested(arguments: CommandLine.arguments)

        _store = StateObject(wrappedValue: AppStore())
    }

    var body: some Scene {
        WindowGroup("DaveTheTrainer") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1040, minHeight: 720)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
