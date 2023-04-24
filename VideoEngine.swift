//
//  VideoEngine.swift
//  MoneyCall
//
//  Created by Tom Lou on 1/21/22.
//
import Foundation
import AgoraRtcKit

class VideoEngine: NSObject { //Subclassing, NSObject is a parent class
    // init AgoraRtcEngineKit
    let config = AgoraRtcEngineConfig()

    override init() {
        let logConfig = AgoraLogConfig()
        // Set the log filter to ERROR
        
        logConfig.level = AgoraLogLevel.info
        // Set the log file path
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmm"
        
        logConfig.filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/logs/\(formatter.string(from: Date())).log"
        
        config.appId = KeyManager.AppId
        //config.areaCode = GlobalSettings.shared.area.rawValue
        config.logConfig = logConfig
    }

    
    lazy var agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    //lazy var agoraEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyManager.AppId, delegate: self)
    
    var contentView: VideoCallView?
}

extension VideoEngine: AgoraRtcEngineDelegate {
    /*
     func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
         isRemoteVideoRender = true
         
         // Only one remote video view is available for this
         // tutorial. Here we check if there exists a surface
         // view tagged as this uid.
         let videoCanvas = AgoraRtcVideoCanvas()
         videoCanvas.uid = uid
         videoCanvas.view = remoteVideo
         videoCanvas.renderMode = .hidden
         agoraKit.setupRemoteVideo(videoCanvas)
     }
     */
    
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        contentView?.log(content: "did join channel")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        contentView?.log(content: "did leave channel")
        contentView?.isLocalAudioMuted = false
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.view = contentView?.remoteCanvas.rendererView
        videoCanvas.renderMode = .hidden
        videoCanvas.uid = uid
        agoraEngine.setupRemoteVideo(videoCanvas)

        contentView?.isRemoteVideoOff = false
        contentView?.isRemoteInSession = true
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    
         //isRemoteVideoRender = false
        contentView?.isRemoteVideoOff = true
        // guard let remoteUid = remoteUid else {
        //    fatalError("remoteUid nil")
         //}
         //print("didOfflineOfUid: \(uid)")
         //if uid == remoteUid {
        contentView?.leaveChannel()
         //}
        print("hell world")
        contentView?.isRemoteInSession = false
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        //isRemoteVideoRender = !muted
        contentView?.isRemoteVideoOff = muted
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        contentView?.log(content: "did occur warning: \(warningCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        contentView?.log(content: "did occur error: \(errorCode.rawValue)")
    }
    
    //extra from the original VideoEngine
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioStateChanged state: AgoraAudioLocalState, error: AgoraAudioLocalError) {
        print(state)
    }
    
    
    //extra from the original VideoEngine
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStateChangedOfUid uid: UInt, state: AgoraAudioRemoteState, reason: AgoraAudioRemoteReason, elapsed: Int) {
        print(reason.rawValue)
    }
     
}
