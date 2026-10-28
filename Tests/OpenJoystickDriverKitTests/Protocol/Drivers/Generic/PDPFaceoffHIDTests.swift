import Foundation
import Testing

@testable import OpenJoystickDriverKit

/// HID element values observed on PDP Faceoff Premiere Wired Pro (0E6F:0184).
struct PDPFaceoffHIDTests {
  private func parse(
    _ driver: HIDDescriptorDriver,
    page: UInt32,
    usage: UInt32,
    value: Int,
    minimum: Int = 0,
    maximum: Int = 255
  ) -> ControllerState? {
    driver.parse(
      elementValue: HIDElementValue(
        usagePage: page,
        usage: usage,
        logicalMinimum: minimum,
        logicalMaximum: maximum,
        integerValue: value
      ),
      receivedAt: MonotonicTimestamp(nanoseconds: 0)
    )?.state
  }

  private func driver() throws -> HIDDescriptorDriver {
    HIDDescriptorDriver(
      model: ControllerModelID(vendorID: 0x0E6F, productID: 0x0184),
      usageMap: try catalogUsageMap(0x0E6F, 0x0184)
    )
  }

  @Test
  func faceButtonsShouldersAndSystemButtons() throws {
    let driver = try driver()
    let controls: [(UInt32, Control)] = [
      (1, .west), (2, .south), (3, .east), (4, .north),
      (5, .leftShoulder), (6, .rightShoulder),
      (7, .leftTrigger), (8, .rightTrigger),
      (9, .back), (10, .start), (13, .guide),
    ]
    for (usage, control) in controls {
      #expect(
        parse(driver, page: 9, usage: usage, value: 1, maximum: 1)?.pressed.contains(control)
          == true
      )
      #expect(
        parse(driver, page: 9, usage: usage, value: 0, maximum: 1)?.pressed.contains(control)
          == false
      )
    }
  }

  @Test
  func rightStickAxesAreNotTriggers() throws {
    let driver = try driver()
    #expect(parse(driver, page: 1, usage: 48, value: 255)?.leftStick.x.normalized == 1)
    #expect(parse(driver, page: 1, usage: 49, value: 0)?.leftStick.y.normalized == -1)
    let x = try #require(parse(driver, page: 1, usage: 50, value: 255))
    #expect(x.rightStick.x.normalized == 1)
    #expect(x.leftTrigger.normalized == 0)
    let y = try #require(parse(driver, page: 1, usage: 53, value: 0))
    #expect(y.rightStick.y.normalized == -1)
    #expect(y.rightTrigger.normalized == 0)
    let neutral = try #require(parse(driver, page: 1, usage: 53, value: 128))
    #expect(abs(neutral.rightStick.y.normalized) < 0.01)
  }

  @Test
  func hatDirectionsAndNeutralFifteen() throws {
    let driver = try driver()
    #expect(parse(driver, page: 1, usage: 57, value: 0, maximum: 7)?.hat == .north)
    #expect(parse(driver, page: 1, usage: 57, value: 2, maximum: 7)?.hat == .east)
    #expect(parse(driver, page: 1, usage: 57, value: 4, maximum: 7)?.hat == .south)
    #expect(parse(driver, page: 1, usage: 57, value: 6, maximum: 7)?.hat == .west)
    #expect(parse(driver, page: 1, usage: 57, value: 15, maximum: 7)?.hat == .neutral)
  }
}
