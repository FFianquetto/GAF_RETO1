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
                    Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255),
                    Color(red: 16 / 255, green: 25 / 255, blue: 38 / 255),
                    Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: 135, y: -260)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard
                    profileCard
                    preferencesCard
                    actionsCard

                    if let feedback {
                        feedbackCard(feedback)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 42)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentProfile()
        }
    }

    private var headerCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
            .frame(height: 136)
            .overlay {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tu configuración")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        Text(displayName.isEmpty ? "Usuario" : displayName)
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)

                        Text(authViewModel.user?.email ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255).opacity(0.8))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                }
                .padding(16)
            }
    }

    private var profileCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Datos principales")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Nombre a mostrar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    TextField("Tu nombre", text: $displayName)
                        .profileInputStyle()

                    Text("Tipo de piel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    Picker("Tipo de piel", selection: $skinType) {
                        ForEach(availableSkinTypes, id: \.value) { type in
                            Text(type.label).tag(type.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                }
            }
        }
    }

    private var preferencesCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Preferencias")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Idioma preferido")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                    Picker("Idioma", selection: $preferredLanguage) {
                        Text("Español").tag("es")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)

                    Toggle("Recibir recomendaciones y recordatorios", isOn: $notificationsEnabled)
                        .font(.system(size: 14, weight: .semibold))
                        .tint(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                        .padding(.top, 4)
                }
            }
        }
    }

    private var actionsCard: some View {
        cardContainer {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Acciones")

                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                        }
                        Text(isSaving ? "Guardando..." : "Guardar perfil")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                    .clipShape(Capsule())
                }
                .disabled(isSaving)
                .buttonStyle(.plain)

                Button("Cerrar sesión", role: .destructive) {
                    authViewModel.signOut()
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(Color.white.opacity(0.9))
                .background(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                .overlay(
                    Capsule()
                        .stroke(Color.red.opacity(0.35), lineWidth: 1.2)
                )
            }
        }
    }

    private func feedbackCard(_ feedback: FeedbackMessage) -> some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.isError ? "xmark.octagon.fill" : "checkmark.circle.fill")
            Text(feedback.text)
                .font(.system(size: 13, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feedback.isError ? Color.red.opacity(0.88) : Color.green.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
            )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
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
            .padding(.horizontal, 14)
            .frame(height: 48)
            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 20 / 255, green: 31 / 255, blue: 45 / 255))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 107 / 255, green: 179 / 255, blue: 1).opacity(0.55), lineWidth: 1.2)
            )
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
