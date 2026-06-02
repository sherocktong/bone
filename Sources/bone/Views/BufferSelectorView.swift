import SwiftUI

struct BufferSelectorView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<7) { index in
                Button(action: {
                    viewModel.selectBuffer(index: index)
                }) {
                    Circle()
                        .fill(Buffer.colors[index])
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                        .opacity(viewModel.selectedBufferIndex == index ? 1.0 : 0.4)
                        .scaleEffect(viewModel.selectedBufferIndex == index ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)
                .help("Buffer \(index + 1): \(Buffer.defaultTitles[index])")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
