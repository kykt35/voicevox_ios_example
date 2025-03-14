//
//  VoiceVoxManager.swift
//  voicevox_ios_example
//
//  Created by Kiyotada Kato on 2025/03/14.
//
import Foundation
import voicevox_core
import AVFoundation

class VoicevoxTTS {
    private var synthesizer: OpaquePointer?
    var player: AVAudioPlayer?

    init() throws {
        let dictionaryPath = Bundle.main.path(forResource: "open_jtalk_dic_utf_8-1.11", ofType: nil)

        var openJtalk: OpaquePointer?
        let result = voicevox_open_jtalk_rc_new(dictionaryPath, &openJtalk)
        guard result == VOICEVOX_RESULT_OK.rawValue else {
            throw NSError(domain: "VoicevoxError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "Failed to initialize OpenJTalk"])
        }

        var onnxruntime: OpaquePointer?
        let ortResult = voicevox_onnxruntime_init_once(&onnxruntime)
        guard ortResult == VOICEVOX_RESULT_OK.rawValue else {
            throw NSError(domain: "VoicevoxError", code: Int(ortResult), userInfo: [NSLocalizedDescriptionKey: "Failed to initialize ONNX Runtime"])
        }
        
        let options = voicevox_make_default_initialize_options()
        let synthResult = voicevox_synthesizer_new(onnxruntime, openJtalk, options, &synthesizer)
        guard synthResult == VOICEVOX_RESULT_OK.rawValue else {
            throw NSError(domain: "VoicevoxError", code: Int(synthResult), userInfo: [NSLocalizedDescriptionKey: "Failed to create synthesizer"])
        }
        
        let vvmsPaths = Bundle.main.paths(forResourcesOfType: "vvm", inDirectory:"models/vvms")

        for modelPath in vvmsPaths {
            if modelPath.hasSuffix(".vvm") {
                print(modelPath)
                print("loading")

                var model: OpaquePointer?
                let result = voicevox_voice_model_file_open(modelPath, &model)
                if result == VOICEVOX_RESULT_OK.rawValue {
                    if let model = model {
                        let loadResult = voicevox_synthesizer_load_voice_model(synthesizer, model)
                        if loadResult != VOICEVOX_RESULT_OK.rawValue {
                            throw NSError(domain: "VoicevoxError", code: Int(loadResult), userInfo: [NSLocalizedDescriptionKey: "Failed load model"])
                        }
                    }
                } else {
                    throw NSError(domain: "VoicevoxError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "Failed open model"])
                }
                voicevox_voice_model_file_delete(model);
            }
        }
    }

    func synthesize(text: String, styleId: UInt32) throws {
        guard let synthesizer = synthesizer else {
            throw NSError(domain: "VoicevoxError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Synthesizer is not initialized"])
        }
        
        var outputWavLength: UInt = 0
        var outputWav: UnsafeMutablePointer<UInt8>?

        let options = voicevox_make_default_tts_options()
        let result = text.withCString { cString in
            voicevox_synthesizer_tts(synthesizer, cString, styleId, options, &outputWavLength, &outputWav)
        }

        guard result == VOICEVOX_RESULT_OK.rawValue, let wavDataPointer = outputWav else {
            throw NSError(domain: "VoicevoxError", code: Int(result), userInfo: [NSLocalizedDescriptionKey: "Failed to synthesize speech"])
        }

        let wavData = Data(bytes: wavDataPointer, count: Int(outputWavLength))
        voicevox_wav_free(wavDataPointer)
        
        if self.player?.isPlaying == true {
            self.player?.stop()
            }
        self.player = try? AVAudioPlayer(data: wavData)
        self.player?.play()
    }
    
    func printMetaJson() {
        if let jsonPointer = voicevox_synthesizer_create_metas_json(synthesizer) {
             // JSONポインタをSwiftの文字列に変換
             let jsonString = String(cString: jsonPointer)
             
             // JSONのメモリを解放
             voicevox_json_free(jsonPointer)
             
             // ログに出力
             print("Voicevox Metas JSON: \(jsonString)")
         } else {
             print("Failed to retrieve Voicevox metas JSON")
         }
    }

    deinit {
        if let synthesizer = synthesizer {
            voicevox_synthesizer_delete(synthesizer)
        }
    }
}
