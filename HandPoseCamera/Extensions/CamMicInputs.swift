//
//  CamMicInputs.swift
//  HGCam
//
//  Created by Aly Salman on 01/03/23.
//  Copyright © 2023 CB Gang. All rights reserved.
//
import UIKit
import Foundation
import AVFoundation
import Vision
import Photos
import SnapKit
import AVKit

var audioPlayer: AVAudioPlayer? //for playing  sound
func loadAudioPlayer(fileName: String, fileType: String) -> AVAudioPlayer? {
    if let sound = Bundle.main.path(forResource: fileName, ofType: fileType) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            return audioPlayer
        } catch {
            print("Error loading sound file: \(error.localizedDescription)")
        }
    }
    return nil
}


