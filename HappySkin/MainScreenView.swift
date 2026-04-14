//
//  MainScreenView.swift
//  HappySkin
//

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Bienvenido") {
                    if let email = authViewModel.user?.email, !email.isEmpty {
                        Text("Sesión iniciada como \(email)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Sesión iniciada")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Asistente IA") {
                    NavigationLink {
                        ChatbotView()
                    } label: {
                        Label("Chatbot de dudas", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                    NavigationLink {
                        SkinAnalysisView()
                    } label: {
                        Label("Camara + prediagnostico", systemImage: "camera.viewfinder")
                    }
                }

                Section("App") {
                    NavigationLink("Abrir contenido existente") {
                        ContentView()
                    }

                    Button("Cerrar sesión", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
            }
            .navigationTitle("HappySkin")
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AuthViewModel())
}
