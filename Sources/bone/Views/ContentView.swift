import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var engine = VimEngine()

    var body: some View {
        VStack(spacing: 0) {
            BufferSelectorView(viewModel: viewModel)
                .frame(maxWidth: .infinity)

            Divider()

            VimTextView(
                initialText: viewModel.selectedBuffer.content,
                onTextChange: { newText in
                    viewModel.updateContent(newText)
                },
                engine: engine
            )
            .id(viewModel.selectedBufferIndex)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack(spacing: 0) {
                Text(engine.mode.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(modeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(.leading, 8)

                Spacer()

                Text(viewModel.selectedBuffer.title)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 300)
        .onReceive(NotificationCenter.default.publisher(for: .selectBuffer)) { notification in
            if let index = notification.object as? Int {
                viewModel.selectBuffer(index: index)
            }
        }
        .onReceive(viewModel.$selectedBufferIndex) { _ in
            // Ensure engine resets to normal mode on buffer switch
            engine.mode = .normal
            engine.commandBuffer = ""
        }
    }

    private var modeColor: Color {
        switch engine.mode {
        case .normal: return .primary
        case .insert: return .green
        case .visual: return .blue
        }
    }
}
