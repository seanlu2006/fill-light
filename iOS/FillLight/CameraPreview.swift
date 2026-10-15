import AVFoundation
import SwiftUI

/// Front camera preview, mirrored like a selfie. Shown inside the ring
/// so you can check how the light falls on your face. Nothing is recorded.
@MainActor
final class FrontCamera: ObservableObject {
    enum Status { case idle, running, denied, unavailable }

    @Published private(set) var status: Status = .idle
    let session = AVCaptureSession()
    private(set) var device: AVCaptureDevice?
    private var configured = false
    private let queue = DispatchQueue(label: "FillLight.camera")

    func start() {
        Task {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                guard await AVCaptureDevice.requestAccess(for: .video) else { status = .denied; return }
            default:
                status = .denied
                return
            }
            guard configureIfNeeded() else { status = .unavailable; return }
            let session = session
            queue.async { if !session.isRunning { session.startRunning() } }
            status = .running
        }
    }

    func stop() {
        let session = session
        queue.async { if session.isRunning { session.stopRunning() } }
        if status == .running { status = .idle }
    }

    private func configureIfNeeded() -> Bool {
        if configured { return true }
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return false }
        session.beginConfiguration()
        session.sessionPreset = .high
        session.addInput(input)
        session.commitConfiguration()
        self.device = device
        configured = true
        return true
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let device: AVCaptureDevice?

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        private var rotation: AVCaptureDevice.RotationCoordinator?
        private var rotationObservation: NSKeyValueObservation?

        /// Keeps the picture upright when the iPhone or iPad rotates.
        func followRotation(of device: AVCaptureDevice) {
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
            rotation = coordinator
            rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] coordinator, _ in
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                DispatchQueue.main.async {
                    guard let connection = self?.previewLayer.connection,
                          connection.isVideoRotationAngleSupported(angle) else { return }
                    connection.videoRotationAngle = angle
                }
            }
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        if let device { view.followRotation(of: device) }
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}
}
