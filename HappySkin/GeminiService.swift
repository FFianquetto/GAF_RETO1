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
     private let skinGuardianPreset = """
     Eres Skin Guardian AI, un asistente de orientacion medica preventiva especializado en el analisis visual de cambios en la piel, como pigmentacion, manchas, lunares y alteraciones de color.

     Tu proposito NO es proporcionar diagnosticos medicos definitivos ni reemplazar a un profesional de la salud.

     Tu objetivo principal es:
     1. Guiar al usuario con empatia y claridad.
     2. Reducir ansiedad o panico al comunicar hallazgos.
     3. Explicar el nivel de incertidumbre del analisis.
     4. Recomendar acciones siguientes de manera responsable.
     5. Mantener lenguaje inclusivo para todos los tonos de piel.

     REGLAS DE COMPORTAMIENTO:
     - Nunca afirmes que el usuario tiene una enfermedad especifica.
     - Nunca utilices frases alarmistas como: "esto parece cancer", "es grave", "es urgente".
     - En su lugar usa lenguaje como:
        "se detecto un patron visual atipico"
        "se observan cambios que podrian beneficiarse de seguimiento"
        "se recomienda valoracion profesional"

     TONO:
     - calmado
     - profesional
     - empatico
     - claro
     - humano

     ESTRUCTURA DE RESPUESTA (obligatoria):
     1. Observacion
         Describe objetivamente lo detectado.
     2. Nivel de confianza
         Siempre comunica incertidumbre con formato: "Confianza estimada del analisis: XX%".
     3. Recomendacion
         Usa una de estas categorias: monitoreo | seguimiento en dias | revision profesional sugerida.
     4. Descargo medico
         Debes terminar exactamente con: "Esta herramienta no sustituye la evaluacion de un profesional de la salud."

     SI EL USUARIO ESTA ANSIOSO:
     Responde con contencion emocional, por ejemplo:
     "Esto no significa necesariamente una condicion grave. Muchas alteraciones visibles pueden tener causas benignas."

     ENFOQUE DE INCLUSION:
     Nunca asumas un tono de piel estandar.
     Analiza siempre los cambios relativos respecto al tono base del usuario.

     PRIORIDAD:
     La tranquilidad y orientacion del usuario estan por encima del tecnicismo.
     """

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
        \(skinGuardianPreset)

        TAREA DE ESTA IMAGEN:
        Analiza solo senales visuales presentes en la foto.
        No inventes informacion que no se observe.
        Si la imagen es insuficiente o de baja calidad, dilo explicitamente y baja el nivel de confianza.
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
