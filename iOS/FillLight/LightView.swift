import SwiftUI

enum LightMode: String, CaseIterable, Identifiable {
    /// The whole screen is the light. Most light; aim it at your face.
    case full
    /// A ring of light with your front camera in the middle, like a selfie ring light.
    case ring

    var id: String { rawValue }
    var title: String { self == .full ? "Full" : "Ring" }
}

struct LightView: View {
    @AppStorage("mode") private var mode: LightMode = .full
    @AppStorage("screenBrightness") private var screenBrightness = 1.0
    @AppStorage("ringWidth") private var ringWidth = 0.5
    @AppStorage("kelvin") private var kelvin = LightMath.defaultKelvin

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var camera = FrontCamera()
    @State private var brightness = ScreenBrightness()
    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?

    private var lightColor: Color {
        let c = LightMath.color(kelvin: kelvin)
        return Color(.sRGB, red: c.red, green: c.green, blue: c.blue)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                lightColor

                if mode == .ring {
                    ringCenter(in: proxy.size)
                }

                // Tapping the light (not the controls) brings the controls back.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { showControls() }

                if controlsVisible {
                    controls
                        .transition(.opacity)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear { activate() }
        .onDisappear { deactivate() }
        .onChange(of: scenePhase) { _, phase in
            phase == .active ? activate() : deactivate()
        }
        .onChange(of: screenBrightness) { _, value in
            brightness.apply(value)
            scheduleHide()
        }
        .onChange(of: mode) { _, _ in
            updateCamera()
            scheduleHide()
        }
        // Keep the controls up while the user is adjusting them.
        .onChange(of: kelvin) { _, _ in scheduleHide() }
        .onChange(of: ringWidth) { _, _ in scheduleHide() }
    }

    // MARK: Ring mode

    private func ringCenter(in size: CGSize) -> some View {
        let shortSide = Double(min(size.width, size.height))
        let thickness = LightMath.ringThickness(brightness: ringWidth, shortSide: shortSide)
        let inner = CGSize(width: max(size.width - thickness * 2, 0), height: max(size.height - thickness * 2, 0))
        let corner = min(thickness * 1.2, min(inner.width, inner.height) / 2)

        return ZStack {
            switch camera.status {
            case .running:
                CameraPreview(session: camera.session, device: camera.device)
            case .denied:
                centerMessage("Allow camera access in Settings to see yourself here.")
            case .unavailable:
                centerMessage("No front camera available.")
            case .idle:
                Color.black
            }
        }
        .frame(width: inner.width, height: inner.height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .shadow(color: lightColor, radius: thickness * 0.3)
    }

    private func centerMessage(_ text: String) -> some View {
        ZStack {
            Color.black
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Picker("Mode", selection: $mode) {
                    ForEach(LightMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                slider("Brightness", value: $screenBrightness, range: 0.2...1,
                       low: "sun.min", high: "sun.max.fill")

                if mode == .ring {
                    slider("Ring width", value: $ringWidth, range: 0...1,
                           low: "circle", high: "circle.circle.fill")
                }

                // Cool on the left, warm on the right.
                slider("Warmth", value: warmthBinding, range: LightMath.kelvinRange,
                       low: "snowflake", high: "flame.fill")
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .frame(maxWidth: 440)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        low: String, high: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: low).frame(width: 22)
            Slider(value: value, in: range)
                .accessibilityLabel(title)
            Image(systemName: high).frame(width: 22)
        }
        .foregroundStyle(.primary)
    }

    private var warmthBinding: Binding<Double> {
        let r = LightMath.kelvinRange
        return Binding(
            get: { r.upperBound + r.lowerBound - kelvin },
            set: { kelvin = r.upperBound + r.lowerBound - $0 }
        )
    }

    private func showControls() {
        withAnimation(.easeOut(duration: 0.2)) { controlsVisible = true }
        scheduleHide()
    }

    /// Controls fade out after a few seconds so the whole screen is light.
    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.4)) { controlsVisible = false }
        }
    }

    // MARK: Lifecycle

    private func activate() {
        UIApplication.shared.isIdleTimerDisabled = true
        brightness.apply(screenBrightness)
        updateCamera()
        scheduleHide()
    }

    private func deactivate() {
        UIApplication.shared.isIdleTimerDisabled = false
        brightness.restore()
        camera.stop()
    }

    private func updateCamera() {
        if mode == .ring && scenePhase == .active {
            camera.start()
        } else {
            camera.stop()
        }
    }
}
