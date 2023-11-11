import Foundation
import Combine

public class SafariDownloadModel: ObservableObject {
    public enum Error: LocalizedError {
        case openFileHandleFailed(URL, code: Int32)
    }

    @Published public var bytesDownloaded: Int
    @Published public var bytesTotal: Int
    @Published public var deleted = false

    public let fileURL: URL
    public let plistURL: URL
    public let originURL: URL
    public let dateAdded: Date
    public let id: UUID
    public let sandboxID: UUID

    private var source: DispatchSourceFileSystemObject!
    private let decoder = PropertyListDecoder()

    public init(url: URL, noObservation: Bool = false) throws {

        plistURL = url.appendingPathComponent("Info.plist")
        let plist = try decoder.decode(DownloadPlist.self, from: Data(contentsOf: plistURL))
        bytesDownloaded = plist.DownloadEntryProgressBytesSoFar
        bytesTotal = plist.DownloadEntryProgressTotalToLoad
        fileURL = URL(fileURLWithPath: plist.DownloadEntryPath)
        guard let url = URL(string: plist.DownloadEntryURL) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "DownloadEntryURL: Not a valid URL string")
            )
        }
        originURL = url
        dateAdded = plist.DownloadEntryDateAddedKey
        id = plist.DownloadEntryIdentifier
        sandboxID = plist.DownloadEntrySandboxIdentifier

        guard !noObservation else { return }

        let fileDescriptor = open(plistURL.path, O_EVTONLY)
        if fileDescriptor == -1 {
            throw Error.openFileHandleFailed(plistURL, code: Darwin.errno)
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .extend],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = source.data
            process(event: event)
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }
        source.resume()
    }

    deinit {
        source?.cancel()
    }

    private func process(event: DispatchSource.FileSystemEvent) {
        if event.contains(.delete) {
            deleted = true
            source?.cancel()
            return
        }
        guard event.contains(.write) || event.contains(.extend) else {
            return
        }

        guard let plist = try? decoder.decode(DownloadPlist.self, from: Data(contentsOf: plistURL)) else {
            return
        }
        bytesDownloaded = plist.DownloadEntryProgressBytesSoFar
        bytesTotal = plist.DownloadEntryProgressTotalToLoad
    }
}
