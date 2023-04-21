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


    
    var videoChatDelegate: VideoChatDelegate?

    let localCanvas = VideoCanvas()
    let remoteCanvas = VideoCanvas()
    
    private let videoEngine = VideoEngine() //get the videoEngine from VideoEngine.swift
    private var rtcEngine: AgoraRtcEngineKit { //equal to agoraKit in OpenDuo
        get {
            return videoEngine.agoraEngine
            //return AgoraRtcEngineKit.sharedEngine(withAppId: KeyManager.AppId, delegate: self)
        }
    }
    
    
    var body: some View {
        ZStack() {
            VideoSessionView(
                backColor: Color("remoteBackColor"),
                backImage: Image("videoMutedIndicator"),
                hideCanvas: isRemoteVideoOff || !isRemoteInSession || !isLocalInSession,
                canvas: remoteCanvas
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
                        canvas: localCanvas
                    ).frame(width: 84, height: 112)
                }.padding()
                Spacer()
                HStack {
                    Button(action: toggleLocalVideo) {
                        Image(isLocalVideoMuted ? "videoMuteButton":"videoMuteButtonSelected")
                            .resizable()
                    }.frame(width: 55, height: 55)
                    Button(action: toggleLocalAudio) {
                        Image(isLocalAudioMuted ? "mute" : "mic")
                            .resizable()
                    }.frame(width: 55, height: 55)
                 
                    Button(action: switchCamera) {
                        Image("switch").resizable()
                    }.frame(width: 55, height: 55)
                    
                    NavigationLink(destination: CallSummaryView(), isActive: $callEnded) {
                        Button(action: toggleLocalSession) {
                            Image(isLocalInSession ? "end" : "call")
                                .resizable()
                        }.frame(width: 70, height: 70)
                    }
                }.padding()
            }
            ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .gradient([.white, Color("ThemeColor")]))
                .frame(width: 50.0, height: 50.0)
        }.onAppear {
            self.initializeAgoraEngine()
            self.setupVideo()
            self.setupLocalVideo()
            self.toggleLocalSession()
        }
        .hiddenTabBar()
        .navigationBarHidden(true)
    }
    
}

struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallView()
    }
}

//Above code is about the view

extension VideoCallView { //used in VideoEngine
    func log(content: String) {
        print(content)
    }
}


 extension VideoCallView {
    func initializeAgoraEngine() {
        videoEngine.contentView = self
    }
    
    func setupVideo() {
        rtcEngine.enableVideo()
        rtcEngine.setVideoEncoderConfiguration(
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
        videoCanvas.view = localCanvas.rendererView
        videoCanvas.renderMode = .hidden
        rtcEngine.setupLocalVideo(videoCanvas)
    }
    
    func joinChannel() {
        
        ApiRequest().makeRequestRTC { status in
            if status == true{
                                           
                rtcEngine.setDefaultAudioRouteToSpeakerphone(true)
                rtcEngine.setChannelProfile(.liveBroadcasting);
                rtcEngine.setClientRole(.broadcaster);
                rtcEngine.joinChannel(byToken: Token.shared().rtcToken, channelId: KeyManager.currentChannel, info: nil, uid: UInt(KeyManager.UserUID)!, joinSuccess: nil)

                
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
        rtcEngine.leaveChannel(nil)
        
        /*
        guard let KeyManager.HostUserUID = remoteUid else {
            fatalError("remoteUid nil")
        }
         */
        
        //delegate?.videoChat(self, didEndChatWith: remoteUid)
        videoChatDelegate?.videoChat(didEndChatWith: KeyManager.HostUserUID)
        
        //videoChatDelegate?.videoChat(didEndChatWith: KeyManager.HostUserUID)
        
        callEnded = true
        isLocalInSession = false
        isLocalAudioMuted = true
        isLocalVideoMuted = true
        isRemoteInSession = false
        isRemoteVideoOff = true
        UIApplication.shared.isIdleTimerDisabled = false
        
    }
}

extension VideoCallView {

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
        rtcEngine.switchCamera()
    }
    
    func toggleLocalAudio() { //equal to didClickMuteButton
        isLocalAudioMuted.toggle()
        rtcEngine.muteLocalAudioStream(isLocalAudioMuted)
    }
    
    func toggleLocalVideo() { //equal to didClickMuteButton
        isLocalVideoMuted.toggle()
        rtcEngine.muteLocalVideoStream(isLocalVideoMuted)
    }
}
