import Foundation
import Combine

class SafariDownloadModel: ObservableObject {
    enum Error: LocalizedError {
        case openFileHandleFailed(URL, code: Int32)
    }

    @Published var bytesDownloaded: Int
    @Published var bytesTotal: Int
    @Published var deleted = false

    let fileURL: URL
    let plistURL: URL
    let originURL: URL
    let dateAdded: Date
    let id: UUID
    let sandboxID: UUID

    private var source: DispatchSourceFileSystemObject!
    private let decoder = PropertyListDecoder()

    init(url: URL, noObservation: Bool = false) throws {

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

    func process(event: DispatchSource.FileSystemEvent) {
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
