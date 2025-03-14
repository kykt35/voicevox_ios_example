//
//  ContentView.swift
//  voicevox_ios_example
//
//  Created by Kiyotada Kato on 2025/03/13.
//

import SwiftUI

struct ContentView: View {
    @State private var text = "こんにちは、これはサンプルのテキストです"
    @State private var styleId = 0
    let voicevoxManager = try! VoicevoxTTS()

    var body: some View {
        VStack {
            TextField("ここにテキストを入力", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("styleID", value: $styleId, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
            
            Button("読み上げる") {
                try! voicevoxManager.synthesize(text: text, styleId: UInt32(styleId))
            }
        }
        .padding()
    }
}
//
//#Preview {
//    ContentView()
//}
