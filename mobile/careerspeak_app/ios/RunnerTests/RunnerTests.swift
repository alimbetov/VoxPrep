import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  @MainActor
  func testExternalLearningVideoHasSystemHTTPSHandler() throws {
    // Native prerequisite only; this does not qualify Flutter tap/return behavior.
    let video = try XCTUnwrap(URL(string: "https://www.youtube.com/watch?v=aqz-KE-bpKQ"))
    XCTAssertTrue(UIApplication.shared.canOpenURL(video))
  }

}
