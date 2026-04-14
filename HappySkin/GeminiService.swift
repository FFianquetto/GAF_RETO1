//
//  GeminiService.swift
//  HappySkin
//

import Foundation
import FirebaseAILogic
import UIKit

final class GeminiService {
    static let shared = GeminiService()

    private let chatModel: GenerativeModel
    private let visionModel: GenerativeModel

    private init() {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        chatModel = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
        visionModel = ai.generativeModel(modelName: "gemini-2.5-flash")
    }

    func startChat() -> Chat {
        chatModel.startChat()
    }

    func sendMessage(_ text: String, using chat: Chat) async throws -> String {
        let response = try await chat.sendMessage(text)
        return response.text ?? "No pude generar una respuesta en este momento."
    }

    func analyzeSkin(image: UIImage) async throws -> String {
        let prompt = """
        Eres un asistente de bienestar de piel. Analiza visualmente la imagen y entrega:
        1) Observaciones visibles objetivas.
        2) Posibles causas comunes NO diagnosticas.
        3) Recomendaciones generales de cuidado (higiene, hidratacion, protector solar, habitos).
        4) Senales de alerta para consultar dermatologia.

        Restricciones:
        - No des diagnostico medico definitivo.
        - No recetes medicamentos.
        - Incluye claramente: 'Esto no sustituye una valoracion medica profesional.'
        """

        let response = try await visionModel.generateContent(image, prompt)
        return response.text ?? "No se pudo generar un analisis."
    }
}
