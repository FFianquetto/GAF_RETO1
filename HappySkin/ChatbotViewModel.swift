//
//  ChatbotViewModel.swift
//  HappySkin
//

import Foundation
import FirebaseAILogic

struct ChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

@MainActor
final class ChatbotViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: "Hola, soy tu asistente de HappySkin. Puedo resolver dudas generales sobre cuidado de la piel y habitos saludables."
        )
    ]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = GeminiService.shared
    private var chat: Chat

    init() {
        chat = service.startChat()
    }

    func sendCurrentMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""
        messages.append(ChatMessage(role: .user, text: trimmed))
        isLoading = true

        do {
            let prompt = """
            Responde de forma clara y breve. Si la pregunta implica diagnostico medico, aclara limites y sugiere acudir con dermatologia.

            Pregunta del usuario:
            \(trimmed)
            """
            let reply = try await service.sendMessage(prompt, using: chat)
            messages.append(ChatMessage(role: .assistant, text: reply))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
