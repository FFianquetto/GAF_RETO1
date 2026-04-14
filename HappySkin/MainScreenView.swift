//
//  MainScreenView.swift
//  HappySkin
//

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.locale) private var locale

    private var displayName: String {
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
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255))
                .ignoresSafeArea()

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(formattedDate)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        Text("Bienvenido: \(displayName)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .lineSpacing(2)

                        statusCard
                        questionsCard
                        actionCard

                        Button("Cerrar sesión") {
                            authViewModel.signOut()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.8))
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 50)
                    .padding(.bottom, 24)
                }
                .navigationBarHidden(true)
            }
        }
    }

    private var statusCard: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .frame(height: 218)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Estado Actual:")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        Text("Saludable")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255))
                    }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                        .frame(height: 155)
                        .overlay {
                            Image(systemName: "heart.text.square.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 92, height: 92)
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        }
                }
                .padding(.horizontal, 13)
                .padding(.top, 15)
            }
    }

    private var questionsCard: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .frame(height: 205)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        Text("¿Tienes alguna duda?")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                    }
                    .padding(.leading, 8)
                    .padding(.top, 6)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        questionChip("¿Cómo se ve mi piel hoy?")
                        questionChip("¿Todo se ve dentro de lo normal?")
                        questionChip("¿Hay zonas que debería cuidar más?")
                        questionChip("¿Mi piel ha cambiado un poco?")
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.top, 8)
            }
    }

    private var actionCard: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .frame(height: 205)
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 72))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        .padding(.top, 12)

                    NavigationLink {
                        ContentView()
                    } label: {
                        Text("Escanear piel")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    }
                    .padding(.horizontal, 41)
                    .padding(.bottom, 10)
                }
            }
    }

    private func questionChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 37)
            .padding(.horizontal, 8)
            .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AuthViewModel())
}
