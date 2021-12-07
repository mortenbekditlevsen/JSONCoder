import XCTest
@testable import JSONCoder
import class JSONCoder.JSONEncoder
import class JSONCoder.JSONDecoder

struct MyCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int? { nil }
  init(stringValue: String) {
    self.stringValue = stringValue
  }
  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
  }
}

struct MyPreformattedCodingKey: PreformattedCodingKey {
  var stringValue: String
  var intValue: Int? { nil }
  init(stringValue: String) {
    self.stringValue = stringValue
  }
  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
  }
}

final class JSONEncoderTests: XCTestCase {
  func testUseSnakeCase() throws {
    struct Model: Codable {
      var imageURL: String
    }
    let encoder = JSONEncoder()
    encoder.keyCodingStrategy = .useSnakeCase
    let data = try encoder.encode(Model(imageURL: "a"))
    let expectedString = "{\"image_url\":\"a\"}"
    XCTAssertEqual(String(data: data, encoding: .utf8), expectedString)
    let decoder = JSONDecoder()
    decoder.keyCodingStrategy = .useSnakeCase
    let model = try decoder.decode(Model.self, from: data)
    XCTAssertEqual(model.imageURL, "a")
  }
  func testCustom() throws {
    struct Model: Codable {
      var imageURL: String
    }
    let encoder = JSONEncoder()
    encoder.keyCodingStrategy = .custom({ codingPath in
      MyCodingKey(stringValue: "\(codingPath.last?.stringValue.hash ?? 0)")
    })
    let data = try encoder.encode(Model(imageURL: "a"))
    let expectedString = "{\"3520785955319405054\":\"a\"}"
    XCTAssertEqual(String(data: data, encoding: .utf8), expectedString)
    let decoder = JSONDecoder()
    decoder.keyCodingStrategy = encoder.keyCodingStrategy
    let model = try decoder.decode(Model.self, from: data)
    XCTAssertEqual(model.imageURL, "a")
  }
  func testPreformattedKey() throws {
    struct Model: Codable {
      var imageURL: String
      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MyPreformattedCodingKey.self)
        try container.encode(imageURL, forKey: .init(stringValue: "imageURL"))
      }
      init(imageURL: String) {
        self.imageURL = imageURL
      }
      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MyPreformattedCodingKey.self)
        self.imageURL = try container.decode(String.self, forKey: .init(stringValue: "imageURL"))
      }
    }
    let encoder = JSONEncoder()
    encoder.keyCodingStrategy = .useSnakeCase
    let data = try encoder.encode(Model(imageURL: "a"))
    let expectedString = "{\"imageURL\":\"a\"}"
    XCTAssertEqual(String(data: data, encoding: .utf8), expectedString)
    let decoder = JSONDecoder()
    decoder.keyCodingStrategy = .useSnakeCase
    let model = try decoder.decode(Model.self, from: data)
    XCTAssertEqual(model.imageURL, "a")
  }
  
  func testNestedKeys() throws {
    struct Model: Codable {
      var imageURL: MyURL
    }
    struct MyURL: Codable {
      var fooBAR: String
    }
    let encoder = JSONEncoder()
    encoder.keyCodingStrategy = .custom({ codingPath in
      MyCodingKey(stringValue: "\(codingPath.last?.stringValue.hash ?? 0)")
    })
    let data = try encoder.encode(Model(imageURL: MyURL(fooBAR: "a")))
    let expectedString = "{\"3520785955319405054\":{\"9203674828077535\":\"a\"}}"
    XCTAssertEqual(String(data: data, encoding: .utf8), expectedString)
    let decoder = JSONDecoder()
    decoder.keyCodingStrategy = encoder.keyCodingStrategy
    let model = try decoder.decode(Model.self, from: data)
    XCTAssertEqual(model.imageURL.fooBAR, "a")

  }
}
