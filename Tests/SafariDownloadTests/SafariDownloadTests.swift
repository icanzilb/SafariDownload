import Foundation
import XCTest
@testable import SafariDownload
import Combine

final class SafariDownloadTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testReadFile() throws {
        let file = try TempResource(resourceNamed: "Xcode_15.0.1.xip", extension: "download")
        let model = try SafariDownloadModel(url: file.url, noObservation: true)
        
        XCTAssertEqual(34, model.bytesDownloaded)
        XCTAssertEqual(100, model.bytesTotal)
        XCTAssertEqual("/Downloads/Xcode_15.0.1.xip.download/Xcode_15.0.1.xip", model.fileURL.path)
        XCTAssertEqual("https://apple.com/Xcode_15.0.1.xip", model.originURL.absoluteString)
    }

    func testObserveDownloadProgress() throws {
        let file = try TempResource(resourceNamed: "Xcode_15.0.1.xip", extension: "download")
        let model = try SafariDownloadModel(url: file.url)

        XCTAssertEqual(34, model.bytesDownloaded)
        XCTAssertEqual(100, model.bytesTotal)

        let plistFileURL = file.url.appendingPathComponent("Info.plist")
        var plist = try PropertyListDecoder().decode(DownloadPlist.self, from: Data(contentsOf: plistFileURL))
        plist.DownloadEntryProgressBytesSoFar = 75
        let newData = try PropertyListEncoder().encode(plist)
        try newData.write(to: plistFileURL)

        let expectation = XCTestExpectation(description: #function)
        model.$bytesDownloaded.dropFirst().first().sink { value in
            XCTAssertEqual(75, value)
            expectation.fulfill()
        }.store(in: &subscriptions)

        wait(for: [expectation], timeout: 2)

        XCTAssertEqual(75, model.bytesDownloaded)
    }

    func testObserveDeleted() throws {
        var file: TempResource? = try TempResource(resourceNamed: "Xcode_15.0.1.xip", extension: "download")
        let model = try SafariDownloadModel(url: file!.url)

        let expectation = XCTestExpectation(description: #function)
        model.$deleted.dropFirst().first().sink { deleted in
            XCTAssertTrue(deleted)
            expectation.fulfill()
        }.store(in: &subscriptions)

        file = nil

        wait(for: [expectation], timeout: 2)
    }
}
