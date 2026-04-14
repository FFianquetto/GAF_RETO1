//
//  LoadingView.swift
//  HappySkin
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LoadingView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(red: 11 / 255, green: 15 / 255, blue: 20 / 255))
                .ignoresSafeArea()

            logoImage
                .frame(width: 259, height: 275)
        }
    }

    @ViewBuilder
    private var logoImage: some View {
#if canImport(UIKit)
        if let path = Bundle.main.path(forResource: "logo", ofType: "png", inDirectory: "Images"),
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
                .padding(64)
        }
#else
        Image(systemName: "sparkles")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color(red: 76 / 255, green: 154 / 255, blue: 1))
            .padding(64)
#endif
    }
}

#Preview {
    LoadingView()
}
