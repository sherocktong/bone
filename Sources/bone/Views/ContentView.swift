import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            BufferSelectorView(viewModel: viewModel)
                .frame(maxWidth: .infinity)

            Divider()

            PlainTextView(
                initialText: viewModel.selectedBuffer.content,
                onTextChange: { newText in
                    viewModel.updateContent(newText)
                }
            )
            .id(viewModel.selectedBufferIndex)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 500, minHeight: 300)
        .onReceive(NotificationCenter.default.publisher(for: .selectBuffer)) { notification in
            if let index = notification.object as? Int {
                viewModel.selectBuffer(index: index)
            }
        }
    }
}
