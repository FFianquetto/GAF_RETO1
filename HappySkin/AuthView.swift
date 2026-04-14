//
//  AuthView.swift
//  HappySkin
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accede a HappySkin")
                        .font(.largeTitle.bold())
                    Text("Inicia sesión con correo, Google o Facebook.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Correo electrónico", text: $authViewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Contraseña", text: $authViewModel.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await authViewModel.signInWithEmail() }
                } label: {
                    Text("Entrar con correo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(authViewModel.isLoading)

                Button {
                    Task { await authViewModel.signUpWithEmail() }
                } label: {
                    Text("Crear cuenta")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(authViewModel.isLoading)

                Divider()

                Button {
                    Task { await authViewModel.signInWithGoogle() }
                } label: {
                    Text("Continuar con Google")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(authViewModel.isLoading)

                Button {
                    Task { await authViewModel.signInWithFacebook() }
                } label: {
                    Text("Continuar con Facebook")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(authViewModel.isLoading)

                if authViewModel.isLoading {
                    ProgressView("Procesando...")
                        .padding(.top, 8)
                }
            }
            .padding()
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
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
