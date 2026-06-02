import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedBufferIndex: Int = 0
    var store: BufferStore

    init(store: BufferStore = BufferStore()) {
        self.store = store
    }

    var selectedBuffer: Buffer {
        get {
            guard selectedBufferIndex >= 0 && selectedBufferIndex < store.buffers.count else {
                return Buffer.default(id: 0)
            }
            return store.buffers[selectedBufferIndex]
        }
    }

    func selectBuffer(index: Int) {
        guard index >= 0 && index < 7 else { return }
        selectedBufferIndex = index
    }

    func updateContent(_ content: String) {
        store.saveBuffer(id: selectedBufferIndex, content: content)
    }
}
