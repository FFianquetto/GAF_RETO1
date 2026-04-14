//
//  SkinAnalysisViewModel.swift
//  HappySkin
//

import Foundation
import UIKit

@MainActor
final class SkinAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var analysisResult = ""
    @Published var isAnalyzing = false
    @Published var errorMessage: String?

    private let service = GeminiService.shared

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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
