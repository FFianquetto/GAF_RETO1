//
//  ProfileView.swift
//  HappySkin
//

import SwiftUI

struct ProfileView: View {
    private struct FeedbackMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var displayName = ""
    @State private var skinType = "normal"
    @State private var preferredLanguage = "es"
    @State private var notificationsEnabled = true
    @State private var isSaving = false
    @State private var feedback: FeedbackMessage?

    private let availableSkinTypes: [(value: String, label: String)] = [
        ("seca", "Seca"),
        ("aspera", "Aspera"),
        ("lisa", "Lisa"),
        ("grasa", "Grasa"),
        ("mixta", "Mixta"),
        ("normal", "Normal"),
        ("sensible", "Sensible"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 245 / 255, green: 250 / 255, blue: 1),
                    Color(red: 234 / 255, green: 244 / 255, blue: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Perfil")
                        .font(.largeTitle.bold())

                    Text("Estas configuraciones se guardan en Firestore dentro de la coleccion Users para tu sesion actual.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let feedback {
                        HStack(spacing: 10) {
                            Image(systemName: feedback.isError ? "xmark.octagon.fill" : "checkmark.circle.fill")
                            Text(feedback.text)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(feedback.isError ? Color.red.opacity(0.9) : Color.green.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Nombre a mostrar")
                            .font(.headline)
                        TextField("Tu nombre", text: $displayName)
                            .profileInputStyle()

                        Text("Tipo de piel")
                            .font(.headline)
                        Picker("Tipo de piel", selection: $skinType) {
                            ForEach(availableSkinTypes, id: \.value) { type in
                                Text(type.label).tag(type.value)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("Idioma preferido")
                            .font(.headline)
                        Picker("Idioma", selection: $preferredLanguage) {
                            Text("Español").tag("es")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.segmented)

                        Toggle("Recibir recomendaciones y recordatorios", isOn: $notificationsEnabled)
                            .font(.headline)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.9))
                    )

                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Guardar perfil")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)

                    Button("Cerrar sesión", role: .destructive) {
                        authViewModel.signOut()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle("Mi perfil")
        .onAppear {
            loadCurrentProfile()
        }
    }

    private func loadCurrentProfile() {
        if let profile = authViewModel.profile {
            displayName = profile.displayName
            skinType = profile.skinType
            preferredLanguage = profile.preferredLanguage
            notificationsEnabled = profile.notificationsEnabled
            return
        }

        if let email = authViewModel.user?.email {
            displayName = email.components(separatedBy: "@").first ?? "Usuario"
        }
    }

    @MainActor
    private func saveProfile() async {
        guard let user = authViewModel.user else {
            showFeedback("No hay una sesion activa.", isError: true)
            return
        }

        isSaving = true
        defer { isSaving = false }

        let sanitizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = user.email?.components(separatedBy: "@").first ?? "Usuario"

        let profile = UserProfile(
            displayName: sanitizedName.isEmpty ? fallbackName : sanitizedName,
            skinType: skinType,
            preferredLanguage: preferredLanguage,
            notificationsEnabled: notificationsEnabled,
            email: user.email ?? "",
            updatedAt: Date()
        )

        do {
            try await authViewModel.saveProfile(profile)
            showFeedback("Perfil guardado correctamente.", isError: false)
        } catch {
            showFeedback(error.localizedDescription, isError: true)
        }
    }

    @MainActor
    private func showFeedback(_ text: String, isError: Bool) {
        let message = FeedbackMessage(text: text, isError: isError)
        withAnimation(.easeInOut(duration: 0.25)) {
            feedback = message
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                if feedback == message {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        feedback = nil
                    }
                }
            }
        }
    }
}

private extension View {
    func profileInputStyle() -> some View {
        self
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.35), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}