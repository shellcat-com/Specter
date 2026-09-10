import AppKit
import TerminalUI

let app = NSApplication.shared
let delegate = SpecterApplication()
app.delegate = delegate
app.run()
