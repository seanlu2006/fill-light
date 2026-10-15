import SwiftUI

@main
struct FillLightApp: App {
    var body: some Scene {
        WindowGroup {
            LightView()
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
        }
    }
}
