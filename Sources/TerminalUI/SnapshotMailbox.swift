import Foundation
import TerminalCore

/// Keeps at most one not-yet-presented snapshot when the main thread is busy.
final class SnapshotMailbox: @unchecked Sendable {
  private let lock = NSLock()
  private var latest: ScreenSnapshot?
  private var scheduled = false
  func offer(_ snapshot: ScreenSnapshot) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    latest = snapshot
    if scheduled { return false }
    scheduled = true
    return true
  }
  func take() -> ScreenSnapshot? {
    lock.lock()
    defer { lock.unlock() }
    let value = latest
    latest = nil
    scheduled = false
    return value
  }
}
