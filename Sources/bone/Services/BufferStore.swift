import Foundation

@MainActor
final class BufferStore: ObservableObject {
    @Published var buffers: [Buffer] = []
    private let buffersDir: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = appSupport.appendingPathComponent("bone", isDirectory: true)
        self.buffersDir = folder.appendingPathComponent("buffers", isDirectory: true)
        try? FileManager.default.createDirectory(at: buffersDir, withIntermediateDirectories: true)

        load()
    }

    private func fileURL(for id: Int) -> URL {
        buffersDir.appendingPathComponent("\(id).json")
    }

    func load() {
        var loaded: [Buffer] = []
        for i in 0..<7 {
            let url = fileURL(for: i)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let data = try Data(contentsOf: url)
                    let buffer = try JSONDecoder().decode(Buffer.self, from: data)
                    loaded.append(buffer)
                } catch {
                    loaded.append(Buffer.default(id: i))
                }
            } else {
                loaded.append(Buffer.default(id: i))
            }
        }
        buffers = loaded
    }

    func saveBuffer(id: Int, content: String) {
        guard id >= 0 && id < buffers.count else { return }
        buffers[id].content = content
        buffers[id].lastModified = Date()

        let url = fileURL(for: id)
        do {
            let data = try JSONEncoder().encode(buffers[id])
            let tempURL = url.appendingPathExtension("tmp")
            try data.write(to: tempURL, options: .atomic)
            // Remove existing file before moving to avoid "file exists" error
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.moveItem(at: tempURL, to: url)
        } catch {
            // Silently ignore save errors to avoid disrupting typing
        }
    }
}
