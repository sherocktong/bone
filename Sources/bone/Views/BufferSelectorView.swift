import SwiftUI

struct BufferSelectorView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<7) { index in
                let isEmpty = viewModel.store.buffers[index].content.isEmpty
                Button(action: {
                    viewModel.selectBuffer(index: index)
                }) {
                    if isEmpty {
                        Circle()
                            .stroke(Buffer.colors[index], lineWidth: 2)
                            .frame(width: 14, height: 14)
                    } else {
                        Circle()
                            .fill(Buffer.colors[index])
                            .frame(width: 14, height: 14)
                    }
                }
                .buttonStyle(.plain)
                .opacity(viewModel.selectedBufferIndex == index ? 1.0 : 0.4)
                .scaleEffect(viewModel.selectedBufferIndex == index ? 1.15 : 1.0)
                .help("Buffer \(index + 1): \(Buffer.defaultTitles[index])")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
