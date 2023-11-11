import Foundation
import XCTest

class TempResource {
    let url: URL

    init(resourceNamed name: String, extension ext: String) throws {
        let fileURL = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: ext))
        let randomName = UUID().uuidString.appending(".\(ext)")
        let targetURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(randomName)
        try? FileManager.default.removeItem(at: targetURL)
        try FileManager.default.copyItem(at: fileURL, to: targetURL)
        url = targetURL
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
