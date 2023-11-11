import Foundation

struct DownloadPlist: Codable {
    var DownloadEntryProgressBytesSoFar: Int
    var DownloadEntryProgressTotalToLoad: Int
    var DownloadEntryPath: String
    var DownloadEntryDateAddedKey: Date
    var DownloadEntryURL: String
    var DownloadEntryIdentifier: UUID
    var DownloadEntrySandboxIdentifier: UUID
}
