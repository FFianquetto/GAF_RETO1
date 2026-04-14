//
//  SkinAnalysisViewModel.swift
//  HappySkin
//

import Foundation
import FirebaseAuth
import UIKit

@MainActor
final class SkinAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult = ""
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var saveMessage: String?

    private let service = GeminiService.shared
    private let scanStore = FirestoreSkinScanStore.shared

    func analyzeSelectedImage() async {
        guard let selectedImage else {
            errorMessage = "Primero toma una foto para analizar."
            return
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let result = try await service.analyzeSkin(image: selectedImage)
            analysisResult = result
            errorMessage = nil

            if let user = Auth.auth().currentUser {
                do {
                    try await scanStore.saveScan(for: user, image: selectedImage, analysisText: result)
                    saveMessage = "Escaneo guardado en tu historial correctamente."
                } catch {
                    saveMessage = nil
                    errorMessage = "Analisis completado, pero no se pudo guardar en historial: \(error.localizedDescription)"
                }
            } else {
                saveMessage = nil
                errorMessage = "Analisis completado, pero no hay sesion activa para guardar historial."
            }
        } catch {
            saveMessage = nil
            errorMessage = error.localizedDescription
        }
    }
}
