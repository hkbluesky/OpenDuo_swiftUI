//
//  HomeScreen.swift
//  MoneyCall
//
//  Created by  on 02/08/21.
//

import SwiftUI
import ActivityIndicatorView
import AgoraRtmKit
import NavigationViewKit

struct HomeScreen: View {
    
    @State var videoCallView = VideoCallView()
    //@State var prepareToVideoChat: (() -> ())?
    @State private var presentVideoCall = false
    @State var index = 0
    //@State var uiTabarController: UITabBarController?
    @State var showLoadingIndicator = false
    var images = ["sample3","sample2","sample1"]
    @State private var selectedLanguage = LocalizationService.shared.language == .english_us ? 0 : 1
    private var language = LocalizationService.shared.language
    @EnvironmentObject var settings: UserSettings
    @State var firstAppear: Bool = true
    @StateObject var myHomeViewModel = MyHomeViewModel()

    var body: some View {
        NavigationView {
            ZStack{
                NavigationLink(destination: AnyView(videoCallView), isActive: $presentVideoCall) { }
                VStack(){
                    VStack(){
                        PagingView(index: $index.animation(), maxIndex: images.count - 1) {
                            ForEach(self.images, id: \.self) { imageName in
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 200)
                    }
                    Spacer()
                    VStack(){
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                        
                        Picker(selection: $selectedLanguage, label: Text("Select language")) {
                            Text("English").tag(0)
                            Text("Chinese").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding([.top,.leading,.trailing],30)
                        .onChange(of: selectedLanguage, perform: { value in
                            if value == 1 {
                                LocalizationService.shared.language = .chinese
                            }else{
                                LocalizationService.shared.language = .english_us
                            }
                        })
                        
                    }
                    .position(x:UIScreen.main.bounds.width/2,y:UIScreen.main.bounds.width/2)
                    
                }
                .navigationTitle(titleName: "Home")
                .toolbar {
                    Button("Sign out") {                       
                        showLoadingIndicator = true
                        User.logout(completion: { result in
                            showLoadingIndicator = false
                            settings.loggedIn = false
                            print("Successfully logged out")
                            ApiRequest().logoutAgora()
                        })
                        
                    }
                    .foregroundColor(Color("ThemeColor"))
                }
                .showTabBar()                
                ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .gradient([.white, Color("ThemeColor")]))
                    .frame(width: 50.0, height: 50.0)
            }
        }.onAppear {
            print(User.current?.username ?? "")
            //callCenter.delegate = self
            //videoCallView.videoChatDelegate = self
            //AgoraRtm.shared().inviterDelegate = 
            KeyManager.HostUserUID = ""
            if User.current?.uid == nil {
                let api = ApiRequest()
                api.fetchCurrentUser(success: {
                    self.makeAgoraRequest()
                }, fail: { error in
                    print(error)
                })
            } else {
                makeAgoraRequest()
            }
        }.navigationViewManager(for: "Home") {
            
        }
    }
}
//////////////////
///
final class MyHomeViewModel: ObservableObject, AgoraRtmInvitertDelegate {
    //@Published var isLocalInSession = false
    @Published var presentVideoCall = false
    //var callCenter = CallCenter()
    private lazy var callCenter = CallCenter(delegate: self)
    var prepareToVideoChat: (() -> ())?

    func log(content: String) {
        print(content)
    }
    
    func pushToVideoCall() {
        print("accepted")
        
        presentVideoCall = true
    }
    
    func close(_ reason: HungupReason) {
//        animationStatus = .off
//        ringStatus = .off
        self.callingVC(reason: reason)
    }
    func inviter(_ inviter: AgoraRtmCallKit, didReceivedIncoming invitation: AgoraRtmInvitation) {
        callCenter.showIncomingCall(of: invitation)
    }
    func inviter(_ inviter: AgoraRtmCallKit, remoteDidCancelIncoming invitation: AgoraRtmInvitation) {
        callCenter.endCall(of: invitation.caller)
    }
    func callingVC(reason: HungupReason) {
        switch reason {
        case .error: break
//            self.showAlert(reason.description)
        case .remoteReject(let remote):
            callCenter.endCall(of: remote)
//            self.showAlert(reason.description + ": \(remote)")
        case .normaly(let remote):
            guard let inviter = AgoraRtm.shared().inviter else {
                fatalError("rtm inviter nil")
            }
            
            let errorHandle: ErrorCompletion = { (error: AGEError) in
//                self?.showAlert(error.localizedDescription)
            }
            
            switch inviter.status {
            case .outgoing:
                callCenter.endCall(of: remote)
                inviter.cancelLastOutgoingInvitation(fail: errorHandle)
            default:
                break
            }
        default:
            break
        }
    }
}

extension HomeScreen {
    
    func makeAgoraRequest(){
        if !self.firstAppear && Token.shared().rtmToken != ""  { return }
        firstAppear = false
        KeyManager.UserUID = "\(User.current?.uid ?? 0)"
        ApiRequest().makeRTMRequest()
    }
}

//extension HomeScreen: AgoraRtmInvitertDelegate {
//}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}

extension MyHomeViewModel: CallCenterDelegate {
    func callCenter(_ callCenter: CallCenter, answerCall session: String) {
        print("callCenter answerCall")

        guard let inviter = AgoraRtm.shared().inviter else {
            fatalError("rtm inviter nil")
        }

        guard let channel = inviter.lastIncomingInvitation?.content else {
            fatalError("lastIncomingInvitation content nil")
        }

        inviter.accpetLastIncomingInvitation()
        self.prepareToVideoChat = {
            KeyManager.HostUserUID = session
            print("HostUserUID: " + KeyManager.HostUserUID)
            KeyManager.currentChannel = channel
            self.pushToVideoCall()
        }
    }

    func callCenter(_ callCenter: CallCenter, declineCall session: String) {
        print("callCenter declineCall")

        guard let inviter = AgoraRtm.shared().inviter else {
            fatalError("rtm inviter nil")
        }

        inviter.refuseLastIncomingInvitation {  (error) in
//            self?.showAlert(error.localizedDescription)
        }
    }

    func callCenter(_ callCenter: CallCenter, startCall session: String) {
        print("callCenter startCall")

        guard let kit = AgoraRtm.shared().kit else {
            fatalError("rtm kit nil")
        }


        guard let inviter = AgoraRtm.shared().inviter else {
            fatalError("rtm inviter nil")
        }

        kit.queryPeerOnline(KeyManager.HostUserUID, success: { (onlineStatus) in
            switch onlineStatus {
            case .online:      sendInvitation()
            case .offline:     self.close(.remoteReject(KeyManager.HostUserUID))
            case .unreachable: self.close(.remoteReject(KeyManager.HostUserUID))
            @unknown default:  fatalError("queryPeerOnline")
            }
        }) { (error) in
            self.close(.error(error))
        }

        // rtm send invitation
        func sendInvitation() {
            let channel = "\(KeyManager.UserUID)-\(KeyManager.HostUserUID)-\(Date().timeIntervalSinceReferenceDate)"

            inviter.sendInvitation(peer: KeyManager.HostUserUID, extraContent: channel, accepted: {
                self.close(.toVideoChat)

                self.callCenter.setCallConnected(of: KeyManager.HostUserUID)
                KeyManager.currentChannel = channel
                self.pushToVideoCall()

            }, refused: {
                self.close(.remoteReject(KeyManager.HostUserUID))
            }) { (error) in
                self.close(.error(error))
            }
        }
    }

    func callCenter(_ callCenter: CallCenter, muteCall muted: Bool, session: String) {
        print("callCenter muteCall")
    }

    func callCenter(_ callCenter: CallCenter, endCall session: String) {
        print("callCenter endCall")
        prepareToVideoChat = nil
    }

    func callCenterDidActiveAudioSession(_ callCenter: CallCenter) {
        print("callCenter didActiveAudioSession")

        // Incoming call
        if let prepare = self.prepareToVideoChat {
            
            prepare()
        }
    }
}

extension MyHomeViewModel: VideoChatDelegate {
    func videoChat(didEndChatWith uid: String) {
        callCenter.endCall(of: uid)
    }
}
