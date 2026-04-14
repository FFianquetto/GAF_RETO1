//
//  MainScreenView.swift
//  HappySkin
//

import SwiftUI

struct MainScreenView: View {
    private struct ChatRoute: Hashable, Identifiable {
        let id = UUID()
        let prompt: String
    }

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.locale) private var locale
    @State private var quickQuestion = ""
    @State private var chatRoute: ChatRoute?

    private var displayName: String {
        if let profileName = authViewModel.profile?.displayName, !profileName.isEmpty {
            return profileName
        }

        if let email = authViewModel.user?.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "User1"
        }
        return "User1"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE d 'DE' MMM"
        return formatter.string(from: Date()).uppercased()
    }

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
                .fill(Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 38)
                .offset(x: 150, y: -300)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        headerCard
                        statusCard
                        questionsCard
                        skinAnalysisCard

                        Button("Cerrar sesión") {
                            authViewModel.signOut()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.8))
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 42)
                    .padding(.bottom, 24)
                }
                .navigationBarHidden(true)
                .navigationDestination(item: $chatRoute) { route in
                    ChatbotView(initialPrompt: route.prompt)
                }
            }
        }
    }

    private var headerCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .frame(height: 136)
            .overlay {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formattedDate)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        Text("Hola, \(displayName)")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 12)

                    NavigationLink {
                        ProfileView()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                            Text("Perfil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                        }
                        .padding(8)
                        .background(Color(red: 18 / 255, green: 24 / 255, blue: 34 / 255))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(16)
            }
    }

    private var statusCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .frame(height: 210)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Estado actual:")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        Text("Saludable")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255))
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                        .frame(height: 147)
                        .overlay {
                            Image(systemName: "heart.text.square.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        }
                }
                .padding(.horizontal, 13)
                .padding(.top, 14)
            }
    }

    private var questionsCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .frame(height: 255)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 11) {
                    HStack(spacing: 10) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        Text("¿Tienes alguna duda?")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                    }
                    .padding(.top, 8)

                    HStack(spacing: 8) {
                        TextField("Escribe tu duda y enviala al chatbot...", text: $quickQuestion, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                        Button {
                            sendQuickQuestion()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        questionChip("¿Cómo se ve mi piel hoy?")
                        questionChip("¿Todo se ve dentro de lo normal?")
                        questionChip("¿Hay zonas que debería cuidar más?")
                        questionChip("¿Mi piel ha cambiado un poco?")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
    }

    private var skinAnalysisCard: some View {
        NavigationLink {
            SkinAnalysisView()
        } label: {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
                .frame(height: 195)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 68))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                            .padding(.top, 8)

                        Text("Escanear mi piel")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                            .padding(.horizontal, 34)
                            .padding(.bottom, 8)
                    }
                }
        }
    }

    private func sendQuickQuestion() {
        let trimmed = quickQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatRoute = ChatRoute(prompt: trimmed)
        quickQuestion = ""
    }

    private func openChat(with prompt: String) {
        chatRoute = ChatRoute(prompt: prompt)
    }

    private func questionChip(_ text: String) -> some View {
        Button {
            openChat(with: text)
        } label: {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 38)
                .padding(.horizontal, 8)
                .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AuthViewModel())
}
