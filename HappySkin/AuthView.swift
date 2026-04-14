//
//  AuthView.swift
//  HappySkin
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255))
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bienvenido a Happy SkinAI")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                        .lineSpacing(2)
                        .padding(.top, 10)

                    Text("Una piel saludable es una piel feliz")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        .padding(.bottom, 6)

                    socialButton(
                        title: "Continuar con Google",
                        icon: "globe"
                    ) {
                        Task { await authViewModel.signInWithGoogle() }
                    }

                    socialButton(
                        title: "Continuar con Facebook",
                        icon: "f.circle.fill"
                    ) {
                        Task { await authViewModel.signInWithFacebook() }
                    }

                    Group {
                        Text("Correo electrónico")
                            .fieldLabelStyle()
                        TextField("", text: $authViewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .authInputStyle()

                        Text("Contraseña")
                            .fieldLabelStyle()
                            .padding(.top, 2)
                        SecureField("", text: $authViewModel.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .authInputStyle()
                    }

                    Button {
                        Task { await authViewModel.signInWithEmail() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                            Text("Continuar")
                                .font(.system(size: 21, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(authViewModel.isLoading)
                    .padding(.top, 8)

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
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 33)
                .padding(.top, 58)
                .padding(.bottom, 20)
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
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 40)
            .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .disabled(authViewModel.isLoading)
    }
}

private extension View {
    func authInputStyle() -> some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color(red: 1, green: 253 / 255, blue: 243 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color(red: 107 / 255, green: 179 / 255, blue: 1), lineWidth: 2)
            )
            .frame(height: 28)
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
            .foregroundStyle(.black)
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
