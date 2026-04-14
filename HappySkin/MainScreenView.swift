//
//  MainScreenView.swift
//  HappySkin
//

import SwiftUI

struct MainScreenView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Main Screen")
                    .font(.largeTitle.bold())

                if let email = authViewModel.user?.email, !email.isEmpty {
                    Text("Sesión iniciada como \(email)")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sesión iniciada")
                        .foregroundStyle(.secondary)
                }

                NavigationLink("Abrir contenido de la app") {
                    ContentView()
                }
                .buttonStyle(.borderedProminent)

                Button("Cerrar sesión") {
                    authViewModel.signOut()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("HappySkin")
        }
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AuthViewModel())
}
