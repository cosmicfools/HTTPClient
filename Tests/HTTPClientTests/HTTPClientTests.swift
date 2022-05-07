import XCTest
@testable import HTTPClient

final class HTTPClientTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let url = URL(string: "http://grawenawer.com") else { return XCTFail() }
        let client = HTTPClient(baseURL: url)
        let expectation = expectation(description: "response should come")
        client.get(path: "/") { (result: Result<APIEmptyRequestResponse, Error>) in
            expectation.fulfill()
            switch result {
            case .success: XCTFail()
            case .failure: XCTAssert(true)
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
