//
//  SkinAnalysisView.swift
//  HappySkin
//

import SwiftUI

struct SkinAnalysisView: View {
    @StateObject private var viewModel = SkinAnalysisViewModel()
    @State private var showCamera = false
    @State private var showCameraUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Analisis de piel con Gemini")
                    .font(.title.bold())

                Text("Sube una foto tomada con camara para obtener observaciones orientativas.")
                    .foregroundStyle(.secondary)

                Group {
                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 240)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.largeTitle)
                                    Text("Aun no hay foto")
                                        .foregroundStyle(.secondary)
                                }
                            }
                    }
                }

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showCameraUnavailable = true
                    }
                } label: {
                    Label("Abrir camara", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await viewModel.analyzeSelectedImage() }
                } label: {
                    Label("Enviar a Gemini", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedImage == nil || viewModel.isAnalyzing)

                if viewModel.isAnalyzing {
                    ProgressView("Analizando imagen...")
                }

                if !viewModel.analysisResult.isEmpty {
                    Text("Prediagnostico orientativo")
                        .font(.headline)

                    Text(viewModel.analysisResult)
                        .padding(12)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("Aviso: esto no sustituye una valoracion medica profesional.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Camara + Gemini")
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $viewModel.selectedImage)
                .ignoresSafeArea()
        }
        .alert("Camara no disponible", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        SkinAnalysisView()
    }
}
