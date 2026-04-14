//
//  ChatbotView.swift
//  HappySkin
//

import SwiftUI

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.role == .assistant {
                                    bubble(text: message.text, isUser: false)
                                    Spacer(minLength: 40)
                                } else {
                                    Spacer(minLength: 40)
                                    bubble(text: message.text, isUser: true)
                                }
                            }
                            .id(message.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                Text("Pensando...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Escribe tu duda sobre cuidado de piel...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button {
                    Task { await viewModel.sendCurrentMessage() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Chatbot")
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func bubble(text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .background(isUser ? Color.blue : Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        ChatbotView()
    }
}
