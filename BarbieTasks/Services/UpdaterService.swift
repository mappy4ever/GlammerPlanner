import Foundation
import Sparkle

/// Thin wrapper around Sparkle's updater for SwiftUI integration.
final class UpdaterService: ObservableObject {
    private let controller: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    static let feedURL = URL(string: "https://raw.githubusercontent.com/mappy4ever/GlammerPlanner/main/appcast.xml")!

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Set feed URL in code (avoids needing custom Info.plist)
        controller.updater.setFeedURL(Self.feedURL)
        do {
            try controller.updater.start()
        } catch {
            print("Sparkle updater failed to start: \(error)")
        }

        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
}
