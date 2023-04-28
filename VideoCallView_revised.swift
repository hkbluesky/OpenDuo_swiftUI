//
//  VideoCallView.swift
//  MoneyCall
//
//  Created by  on 24/08/21.
//

import Foundation
import SwiftUI
import AgoraUIKit
import AgoraRtcKit
import ActivityIndicatorView


protocol VideoChatDelegate: AnyObject {
    func videoChat(didEndChatWith uid: String)
}

struct VideoCallView: View {
    @StateObject var videoCallViewModel = VideoCallViewModel()
    @State var isLocalInSession = false //moved from openduo: localVideo //checked
    @State var isLocalAudioMuted = false //moved from openduo: localVideoMutedIndicator
    @State var isLocalVideoMuted = false //moved from openduo: localVideoMutedIndicator
    
    @State var isRemoteInSession = false
    @State var isRemoteVideoOff = true //moved from openduo: remoteVideoMutedIndicator ////isRemoteVideoMuted in the example project
    @State var showLoadingIndicator = false
    
    //@State var micButton = false    //appeared in Openduo
    //@State var cameraButton = false //appeared in Openduo
    @State var callEnded = false
    @State var token: String?


    
   

    //@StateObject var localCanvas
    //@StateObject var remoteCanvas = VideoCanvas()
    
    

    
    
    var body: some View {
        ZStack() {
            VideoSessionView(
                backColor: Color("remoteBackColor"),
                backImage: Image("videoMutedIndicator"),
                hideCanvas: isRemoteVideoOff || !isRemoteInSession || !isLocalInSession,
                canvas: VideoCanvas(rendererView: videoCallViewModel.remoteCanvasView)//videoCallViewModel.remoteCanvas
            ).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    VideoSessionView(
                        backColor: Color(.systemGray5),
                        backImage: Image("videoMutedIndicator")
                            .resizable(),
                        //hideCanvas: !isLocalInSession || isLocalVideoMuted, //different from the example code
                        hideCanvas: isLocalVideoMuted, //different from the example code

                        //hideCanvas: false, //different from the example code
                        canvas: VideoCanvas(rendererView: videoCallViewModel.localCanvasView)
                    ).frame(width: 84, height: 112)
                }.padding()
                Spacer()
                HStack {
                    Button(action: videoCallViewModel.toggleLocalVideo) {
                        Image(isLocalVideoMuted ? "videoMuteButton":"videoMuteButtonSelected")
                            .resizable()
                    }.frame(width: 55, height: 55)
                    Button(action: videoCallViewModel.toggleLocalAudio) {
                        Image(isLocalAudioMuted ? "mute" : "mic")
                            .resizable()
                    }.frame(width: 55, height: 55)
                 
                    Button(action: videoCallViewModel.switchCamera) {
                        Image("switch").resizable()
                    }.frame(width: 55, height: 55)
                    
                    NavigationLink(destination: CallSummaryView(), isActive: $callEnded) {
                        Button(action: videoCallViewModel.toggleLocalSession) {
                            Image(isLocalInSession ? "end" : "call")
                                .resizable()
                        }.frame(width: 70, height: 70)
                    }
                }.padding()
            }
            ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .gradient([.white, Color("ThemeColor")]))
                .frame(width: 50.0, height: 50.0)
        }.onAppear {
            videoCallViewModel.initializeAgoraEngine()
            videoCallViewModel.setupVideo()
            videoCallViewModel.setupLocalVideo()
            videoCallViewModel.toggleLocalSession()
        }
        .hiddenTabBar()
        .navigationBarHidden(true)
    }
    
}


final class VideoCallViewModel: NSObject, ObservableObject {
    //private let videoEngine = VideoEngine() //get the videoEngine from VideoEngine.swift
    @Published var isLocalVideoMuted = true
    @Published var isLocalInSession = false //moved from openduo: localVideo //checked
    @Published var isLocalAudioMuted = false //moved from openduo: localVideoMutedIndicator
    @Published var isRemoteInSession = false
    @Published var isRemoteVideoOff = true //moved from openduo: remoteVideoMutedIndicator ////isRemoteVideoMuted in the example project
    @Published var showLoadingIndicator = false
    //@State var micButton = false    //appeared in Openduo
    //@State var cameraButton = false //appeared in Openduo
    @Published var callEnded = false
    @Published var token: String?
    
    let localCanvasView = UIView()
    let remoteCanvasView = UIView()

    var videoChatDelegate: VideoChatDelegate?
    
    private var agoraEngine: AgoraRtcEngineKit!
   // private var rtcEngine: AgoraRtcEngineKit { //equal to agoraKit in OpenDuo
   //     get {
   //         return videoEngine.agoraEngine
            //return AgoraRtcEngineKit.sharedEngine(withAppId: KeyManager.AppId, delegate: self)
   //     }
    //}
}



//Above code is about the view

extension VideoCallViewModel { //used in VideoEngine
    func log(content: String) {
        print(content)
    }
}


 extension VideoCallViewModel {
     //weak var delegate: VideoChatVCDelegate?
     
    func initializeAgoraEngine() {
        let config = AgoraRtcEngineConfig()
        
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
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        //return agoraEngine;
    }
    
    func setupVideo() {
        agoraEngine.enableVideo()
        agoraEngine.setVideoEncoderConfiguration(
            AgoraVideoEncoderConfiguration(
                size: AgoraVideoDimension640x360,
                frameRate: .fps15,
                bitrate: AgoraVideoBitrateStandard,
                orientationMode: .adaptative,
                mirrorMode: AgoraVideoMirrorMode.disabled
        ))
    }
    
    
    func setupLocalVideo() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localCanvasView
        videoCanvas.renderMode = .hidden
        agoraEngine.setupLocalVideo(videoCanvas)
    }
    
    func joinChannel() {
        
        ApiRequest().makeRequestRTC { status in
            if status == true{
                                           
                self.agoraEngine.setDefaultAudioRouteToSpeakerphone(true)
                self.agoraEngine.setChannelProfile(.liveBroadcasting);
                self.agoraEngine.setClientRole(.broadcaster);
                self.agoraEngine.joinChannel(byToken: Token.shared().rtcToken, channelId: KeyManager.currentChannel, info: nil, uid: UInt(KeyManager.UserUID)!, joinSuccess: nil)

                
                //rtcEngine.setAudioSessionOperationRestriction(.all)
                //rtcEngine.setDefaultAudioRouteToSpeakerphone(true)
                //rtcEngine.joinChannel(byToken: Token.shared().rtcToken, channelId: KeyManager.currentChannel, info: nil, uid: UInt(KeyManager.UserUID)!, joinSuccess: nil)
                
                //videoChatDelegate?.videoChat(didEndChatWith: KeyManager.HostUserUID)
                
                self.isLocalVideoMuted = false
                //isStartCalling = true
                //UIApplication.shared.isIdleTimerDisabled = true
                //self.contentView?.log(content: "did join channel")
                
            } else{
                print("Failed to get RTC token")
                //self.contentView?.log(content: "Failed to get RTC token")  //added self
            }
        }
    }
    
    func leaveChannel() {
        self.agoraEngine.leaveChannel(nil)
        
        /*
        guard let KeyManager.HostUserUID = remoteUid else {
            fatalError("remoteUid nil")
        }
         */
        
        //delegate?.videoChat(self, didEndChatWith: remoteUid)
        
        //let myViewModelObj = CallViewModel()
        //myViewModelObj.videoChat(didEndChatWith: KeyManager.HostUserUID)
        //delegate?.videoChat(didEndChatWith: KeyManager.HostUserUID)
        
        videoChatDelegate?.videoChat(didEndChatWith: KeyManager.HostUserUID)
        
        callEnded = true
        isLocalInSession = false
        isLocalAudioMuted = true
        isLocalVideoMuted = true
        isRemoteInSession = false
        isRemoteVideoOff = true
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
}

extension VideoCallViewModel {

    func toggleLocalSession() { //equal to pressing hangout button
        isLocalInSession.toggle()
        
        //disable network call when in the Preview mode
        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1") {
            if isLocalInSession {
                joinChannel()
            } else {
                leaveChannel()
            }
        }
    }
    
    func switchCamera() { //equal to didClickSwitchCameraButton
        agoraEngine.switchCamera()
    }
    
    func toggleLocalAudio() { //equal to didClickMuteButton
        isLocalAudioMuted.toggle()
        agoraEngine.muteLocalAudioStream(isLocalAudioMuted)
    }
    
    func toggleLocalVideo() { //equal to didClickMuteButton
        isLocalVideoMuted.toggle()
        agoraEngine.muteLocalVideoStream(isLocalVideoMuted)
    }
}



/*
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
 */

extension VideoCallViewModel: AgoraRtcEngineDelegate {
    
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
    
    
    
    
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        log(content: "did join channel")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        log(content: "did leave channel")
        self.isLocalAudioMuted = false
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.view = remoteCanvasView
        videoCanvas.renderMode = .hidden
        videoCanvas.uid = uid
        agoraEngine.setupRemoteVideo(videoCanvas)

        self.isRemoteVideoOff = false
        self.isRemoteInSession = true
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
    
         //isRemoteVideoRender = false
        self.isRemoteVideoOff = true
        // guard let remoteUid = remoteUid else {
        //    fatalError("remoteUid nil")
         //}
         //print("didOfflineOfUid: \(uid)")
         //if uid == remoteUid {
        self.leaveChannel()
         //}
        print("hell world")
        self.isRemoteInSession = false
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        //isRemoteVideoRender = !muted
        self.isRemoteVideoOff = muted
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        log(content: "did occur warning: \(warningCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        log(content: "did occur error: \(errorCode.rawValue)")
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


struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallView()
    }
}
