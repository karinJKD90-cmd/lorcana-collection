import SwiftUI
import AVFoundation

struct LiveCameraView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var shouldCapture: Bool

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onImageCaptured = { image in
            DispatchQueue.main.async {
                capturedImage = image
                shouldCapture = false
            }
        }
        view.setup()
        return view
    }

    func updateUIView(_ view: CameraPreviewView, context: Context) {
        if shouldCapture {
            view.capturePhoto()
        }
    }
}

class CameraPreviewView: UIView {
    var onImageCaptured: ((UIImage?) -> Void)?
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var isCapturing = false

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    func setup() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async { self?.startSession() }
        }
    }

    private func startSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        self.session = session
        self.photoOutput = output
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    deinit { session?.stopRunning() }
}

extension CameraPreviewView: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        isCapturing = false
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        onImageCaptured?(image)
    }
}
