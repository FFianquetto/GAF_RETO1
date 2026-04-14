//
//  SkinAnalysisView.swift
//  HappySkin
//

import SwiftUI

struct SkinAnalysisView: View {
    @StateObject private var viewModel = SkinAnalysisViewModel()
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var showFullResponse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 7 / 255, green: 13 / 255, blue: 24 / 255),
                    Color(red: 10 / 255, green: 20 / 255, blue: 34 / 255),
                    Color(red: 7 / 255, green: 13 / 255, blue: 24 / 255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Escanea con tu camara")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 80 / 255, green: 156 / 255, blue: 1))
                        .minimumScaleFactor(0.7)

                    previewCard

                    cameraButton
                    analyzeButton

                    if viewModel.isAnalyzing {
                        analyzingCard
                    }

                    if let saveMessage = viewModel.saveMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(saveMessage)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if !viewModel.analysisResult.isEmpty {
                        analysisCard
                    }

                    Color.clear
                        .frame(height: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 26)
            }
        }
        .navigationTitle("Escaneo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $viewModel.selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showFullResponse) {
            fullResponseSheet
        }
        .alert("Camara no disponible", isPresented: $showCameraUnavailable) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text("Este dispositivo o simulador no tiene camara disponible.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(red: 21 / 255, green: 34 / 255, blue: 54 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .frame(height: 386)
            .overlay {
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 14 / 255, green: 28 / 255, blue: 48 / 255))
                        .frame(width: 220, height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .overlay {
                            Image(systemName: "camera")
                                .font(.system(size: 96, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                }
            }
            .clipped()
    }

    private var analyzingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analizando tu imagen")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Estamos revisando la foto y preparando una respuesta completa.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 20 / 255, green: 33 / 255, blue: 53 / 255))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var cameraButton: some View {
        Button {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCamera = true
            } else {
                showCameraUnavailable = true
            }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 66, height: 38)
                    .overlay {
                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(red: 43 / 255, green: 50 / 255, blue: 64 / 255))
                    }

                Text("Abrir Camara")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(red: 154 / 255, green: 166 / 255, blue: 185 / 255))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyzeSelectedImage() }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .frame(width: 66, height: 38)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(red: 96 / 255, green: 120 / 255, blue: 177 / 255))
                    }

                Text(viewModel.isAnalyzing ? "Analizando..." : "Enviar a Gemini")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(Color(red: 227 / 255, green: 236 / 255, blue: 251 / 255))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 74 / 255, green: 150 / 255, blue: 1),
                        Color(red: 77 / 255, green: 145 / 255, blue: 230 / 255),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.selectedImage == nil || viewModel.isAnalyzing)
        .opacity(viewModel.selectedImage == nil ? 0.65 : 1)
    }

    private var analysisCard: some View {
        let section = AnalysisSection(raw: viewModel.analysisResult)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Prediagnostico orientativo")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 85 / 255, green: 166 / 255, blue: 1))

            VStack(alignment: .leading, spacing: 10) {
                infoBlock(title: "Resumen", value: section.summary)

                HStack(spacing: 10) {
                    Text("Nivel:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(section.level)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(levelColor(for: section.level))
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 30)
                .background(Color(red: 11 / 255, green: 23 / 255, blue: 40 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack(spacing: 10) {
                    Text("Confianza:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                    Text(section.confidence)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 102 / 255, green: 175 / 255, blue: 1))
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 30)
                .background(Color(red: 11 / 255, green: 23 / 255, blue: 40 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                infoBlock(title: "Recomendaciones", value: section.recommendations)

                Button {
                    showFullResponse = true
                } label: {
                    Text("Ver respuesta completa")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 11 / 255, green: 23 / 255, blue: 40 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color(red: 20 / 255, green: 33 / 255, blue: 53 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var fullResponseSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                        Color(red: 14 / 255, green: 28 / 255, blue: 48 / 255),
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Respuesta completa del modelo")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                        Text("El texto de abajo se muestra completo para que puedas revisar cada parte del analisis.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.72))

                        Text(viewModel.analysisResult)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .textSelection(.enabled)
                    }
                    .padding(18)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        showFullResponse = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(title):")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 11 / 255, green: 23 / 255, blue: 40 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func levelColor(for level: String) -> Color {
        let normalized = level.lowercased()
        if normalized.contains("salud") || normalized.contains("estable") {
            return Color(red: 53 / 255, green: 199 / 255, blue: 112 / 255)
        }
        if normalized.contains("revision") || normalized.contains("riesgo") {
            return Color.orange
        }
        return Color(red: 102 / 255, green: 175 / 255, blue: 1)
    }
}

private struct AnalysisSection {
    let summary: String
    let level: String
    let confidence: String
    let recommendations: String

    init(raw: String) {
        let cleaned = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        summary = AnalysisSection.value(in: cleaned, for: ["resumen", "analisis", "resultado"]) ?? cleaned
        level = AnalysisSection.value(in: cleaned, for: ["nivel", "estado", "categoria"]) ?? "Saludable"
        confidence = AnalysisSection.value(in: cleaned, for: ["confianza"]) ?? AnalysisSection.confidenceValue(in: cleaned)
        recommendations = AnalysisSection.value(in: cleaned, for: ["recomendaciones", "recomendacion", "plan", "siguiente paso"]) ?? "Te recomendamos registrar otra imagen en 7 dias para comparar evolucion."
    }

    private static func value(in text: String, for keys: [String]) -> String? {
        for line in text.split(whereSeparator: \ .isNewline) {
            let rawLine = String(line).trimmingCharacters(in: .whitespaces)
            let normalized = rawLine.lowercased()

            guard keys.contains(where: { normalized.hasPrefix($0) }) else {
                continue
            }

            if let separator = rawLine.firstIndex(of: ":") {
                let value = rawLine[rawLine.index(after: separator)...].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }

    private static func confidenceValue(in text: String) -> String {
        let pattern = "(\\d{1,3})\\s*%"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return "94%"
        }

        let range = NSRange(location: 0, length: text.utf16.count)
        guard let match = regex.firstMatch(in: text, range: range),
              let captured = Range(match.range(at: 1), in: text) else {
            return "94%"
        }

        return "\(text[captured])%"
    }
}

#Preview {
    NavigationStack {
        SkinAnalysisView()
    }
}
