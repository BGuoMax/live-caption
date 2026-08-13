import CoreMedia
import Foundation
import ScreenCaptureKit

final class SystemAudioCapture: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private let outputQueue = DispatchQueue(label: "LiveCaption.SystemAudio")
    private var stream: SCStream?
    private var onBuffer: (@Sendable (CMSampleBuffer) -> Void)?

    func start(onBuffer: @escaping @Sendable (CMSampleBuffer) -> Void) async throws {
        await stop()
        self.onBuffer = onBuffer

        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            throw Self.permissionAwareError(error)
        }
        guard let display = content.displays.first else {
            throw LiveCaptionError.noDisplayAvailable
        }

        let ownBundleID = Bundle.main.bundleIdentifier
        let excludedApps = content.applications.filter { app in
            guard let ownBundleID else { return false }
            return app.bundleIdentifier == ownBundleID
        }
        let filter = SCContentFilter(
            display: display,
            excludingApplications: excludedApps,
            exceptingWindows: []
        )

        let configuration = SCStreamConfiguration()
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 2)
        configuration.queueDepth = 1
        configuration.showsCursor = false
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 1

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        do {
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: outputQueue)
            try await stream.startCapture()
        } catch {
            throw Self.permissionAwareError(error)
        }
        self.stream = stream
    }

    func stop() async {
        guard let stream else { return }
        do {
            try await stream.stopCapture()
        } catch {
            // The stream may already have stopped after a permission or device change.
        }
        self.stream = nil
        onBuffer = nil
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .audio, sampleBuffer.isValid else { return }
        onBuffer?(sampleBuffer)
    }

    func stream(_ stream: SCStream, didStopWithError error: any Error) {
        onBuffer = nil
    }

    private static func permissionAwareError(_ error: any Error) -> any Error {
        let nsError = error as NSError
        if nsError.domain == SCStreamErrorDomain,
           nsError.code == SCStreamError.Code.userDeclined.rawValue {
            return LiveCaptionError.screenCapturePermissionDenied
        }
        return error
    }
}
