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
    @StateObject private var historyViewModel = SkinScanHistoryViewModel()
    @State private var quickQuestion = ""
    @State private var chatRoute: ChatRoute?
    @State private var isShowingFullHistory = false
    @State private var selectedScanDetail: SkinScanRecord?

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
            Color(red: 5 / 255, green: 11 / 255, blue: 22 / 255)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 4 / 255, green: 10 / 255, blue: 22 / 255),
                    Color(red: 8 / 255, green: 24 / 255, blue: 48 / 255),
                    Color(red: 5 / 255, green: 12 / 255, blue: 26 / 255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 54)
                .offset(x: 150, y: -300)

            Circle()
                .fill(Color(red: 111 / 255, green: 190 / 255, blue: 255 / 255).opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .offset(x: -140, y: 340)

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        headerCard
                        statusCard
                        skinAnalysisCard
                        questionsCard

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
                .task(id: authViewModel.user?.uid) {
                    await historyViewModel.refresh(for: authViewModel.user)
                }
                .sheet(item: $selectedScanDetail) { scan in
                    scanDetailSheet(for: scan)
                }
                .sheet(isPresented: $isShowingFullHistory) {
                    fullHistorySheet
                }
            }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Estado actual")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                Spacer(minLength: 8)

                if let latestScan = historyViewModel.latestScan {
                    Text(latestScan.recommendation.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(recommendationColor(for: latestScan.recommendation))
                        .clipShape(Capsule())
                }
            }

            if historyViewModel.isLoading {
                ProgressView("Cargando historial...")
                    .tint(.white)
                    .foregroundStyle(.white.opacity(0.85))
            } else if let latestScan = historyViewModel.latestScan {
                HStack(alignment: .top, spacing: 12) {
                    if let image = latestScan.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 92)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(latestScan.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        Text(latestScan.analysisText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                            .lineLimit(5)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title)
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                            Text("Aun no tienes escaneos guardados")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                        }
                    }
            }

            if let error = historyViewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.85))
            }

            Button {
                if let latestScan = historyViewModel.latestScan {
                    selectedScanDetail = latestScan
                }
            } label: {
                Text("Mostrar vista completa")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(historyViewModel.latestScan == nil)
            .opacity(historyViewModel.latestScan == nil ? 0.55 : 1)

            Button {
                isShowingFullHistory = true
            } label: {
                Text("Mostrar historial de respuestas")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(historyViewModel.scans.isEmpty)
            .opacity(historyViewModel.scans.isEmpty ? 0.55 : 1)
        }
        .padding(14)
        .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func scanDetailSheet(for scan: SkinScanRecord) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                        Color(red: 14 / 255, green: 28 / 255, blue: 48 / 255),
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detalle del escaneo")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                        Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        fullTextCard(scan.analysisText)
                    }
                    .padding(18)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        selectedScanDetail = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var fullHistorySheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                        Color(red: 14 / 255, green: 28 / 255, blue: 48 / 255),
                        Color(red: 8 / 255, green: 14 / 255, blue: 26 / 255),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Historial completo de escaneos")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))

                        if historyViewModel.scans.isEmpty {
                            Text("Aun no tienes escaneos guardados.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.7))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(historyViewModel.scans) { scan in
                                    fullHistoryRow(for: scan)
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        isShowingFullHistory = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var questionsCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
            )
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

                    HStack(spacing: 10) {
                        TextField("Escribe tu pregunta...", text: $quickQuestion, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(red: 22 / 255, green: 33 / 255, blue: 50 / 255))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        quickQuestion.isEmpty ? 
                                        Color.white.opacity(0.15) :
                                        Color(red: 107 / 255, green: 179 / 255, blue: 1).opacity(0.6),
                                        lineWidth: 1.5
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color(red: 240 / 255, green: 245 / 255, blue: 250 / 255))

                        Button {
                            sendQuickQuestion()
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 48, height: 48)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 76 / 255, green: 154 / 255, blue: 1))
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
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                )
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

    private func recommendationColor(for recommendation: String) -> Color {
        switch recommendation.lowercased() {
        case "revision profesional sugerida":
            return Color.orange.opacity(0.9)
        case "seguimiento en dias":
            return Color(red: 76 / 255, green: 154 / 255, blue: 1)
        default:
            return Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255)
        }
    }

    private func fullHistoryRow(for scan: SkinScanRecord) -> some View {
        Button {
            selectedScanDetail = scan
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if let image = scan.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 19 / 255, green: 26 / 255, blue: 36 / 255))
                        .frame(width: 70, height: 70)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(scan.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))

                        Spacer(minLength: 8)

                        Text(scan.recommendation.capitalized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(recommendationColor(for: scan.recommendation))
                            .clipShape(Capsule())
                    }

                    Text(scan.analysisText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
                        .lineLimit(4)

                    if let confidence = scan.confidence {
                        Text("Confianza: \(Int(confidence))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 107 / 255, green: 179 / 255, blue: 1))
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func fullTextCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(red: 26 / 255, green: 34 / 255, blue: 48 / 255))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .textSelection(.enabled)
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 40)
                .padding(.horizontal, 10)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 76 / 255, green: 154 / 255, blue: 1),
                            Color(red: 66 / 255, green: 144 / 255, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color(red: 76 / 255, green: 154 / 255, blue: 1).opacity(0.3), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainScreenView()
        .environmentObject(AuthViewModel())
}
