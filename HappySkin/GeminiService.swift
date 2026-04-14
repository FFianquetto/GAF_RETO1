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
        let preparedImage = image.normalizedForGemini(maxDimension: 1536, compressionQuality: 0.85)

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

        do {
            let response = try await generateVisionContent(prompt: prompt, image: preparedImage)
            return response.text ?? "No se pudo generar un analisis."
        } catch {
            if isTransientGeminiError(error) {
                throw GeminiServiceError.modelBusy
            }

            throw error
        }
    }

    private func generateVisionContent(prompt: String, image: UIImage) async throws -> GenerateContentResponse {
        do {
            return try await visionModel.generateContent(prompt, image)
        } catch {
            if isTransientGeminiError(error) {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return try await visionModel.generateContent(prompt, image)
            }

            throw error
        }
    }

    private func isTransientGeminiError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let message = nsError.localizedDescription.lowercased()
        return nsError.code == 500 || message.contains("high demand") || message.contains("internal")
    }
}

private enum GeminiServiceError: LocalizedError {
    case modelBusy

    var errorDescription: String? {
        switch self {
        case .modelBusy:
            return "Gemini está ocupado ahora mismo. Intenta de nuevo en unos segundos."
        }
    }
}

private extension UIImage {
    func normalizedForGemini(maxDimension: CGFloat, compressionQuality: CGFloat) -> UIImage {
        let sourceImage = normalizedOrientationImage()
        let longestSide = max(sourceImage.size.width, sourceImage.size.height)

        guard longestSide > maxDimension else {
            return sourceImage
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        let resizedImage = renderer.image { _ in
            sourceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let jpegData = resizedImage.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: jpegData) else {
            return resizedImage
        }

        return compressedImage
    }

    func normalizedOrientationImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
