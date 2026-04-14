//
//  AuthView.swift
//  HappySkin
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255),
                    Color(red: 15 / 255, green: 24 / 255, blue: 35 / 255),
                    Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: 130, y: -230)

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 74, height: 74)

                        Text("Happy SkinAI")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))

                        Text("Inicia sesion para continuar con tu rutina")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    }
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 16) {
                        socialButton(
                            title: "Continuar con Google",
                            icon: "globe"
                        ) {
                            Task { await authViewModel.signInWithGoogle() }
                        }

                        HStack(spacing: 10) {
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 1)
                            Text("o con correo")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.55))
                            Rectangle()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 1)
                        }

                        Group {
                            Text("Correo electronico")
                                .fieldLabelStyle()
                            TextField("tu@correo.com", text: $authViewModel.email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .authInputStyle()

                            Text("Contrasena")
                                .fieldLabelStyle()
                                .padding(.top, 2)
                            SecureField("Ingresa tu contrasena", text: $authViewModel.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .authInputStyle()
                        }

                        Button {
                            Task { await authViewModel.signInWithEmail() }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                                Text("Continuar")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(authViewModel.isLoading)
                        .padding(.top, 4)

                        Button {
                            Task { await authViewModel.signUpWithEmail() }
                        } label: {
                            Text("Crear cuenta")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(authViewModel.isLoading)

                        if authViewModel.isLoading {
                            ProgressView("Procesando...")
                                .tint(.white)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 2)
                        }
                    }
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 16 / 255, green: 26 / 255, blue: 38 / 255).opacity(0.86))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 42)
                .padding(.bottom, 24)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { authViewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    authViewModel.errorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
    }

    private func socialButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 52)
            .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(authViewModel.isLoading)
    }
}

private extension View {
    func authInputStyle() -> some View {
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

    func fieldLabelStyle() -> some View {
        font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
