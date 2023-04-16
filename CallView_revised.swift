//
//  CallView.swift
//  MoneyCall
//
//  Created by  on 02/11/21.
//

import SwiftUI
import AudioToolbox
import AgoraRtmKit

public struct CallView: View {
    
    var user: User
    @State var prepareToVideoChat: (() -> ())?
    @State var isLocalInSession = false
    @State var cancelCall = false
    @State private var presentVideoCall = false
    private var timer: Timer?
    private var soundId = SystemSoundID()
    @State var videoCallView = VideoCallView()
    
//    let callEngine = CallEngine()
    var callCenter = CallCenter()
    
    enum Operation {
        case on, off
    }
    
    private var ringStatus: Operation = .off {
        didSet {
            guard oldValue != ringStatus else {
                return
            }
            
            switch ringStatus {
            case .on:  startPlayRing()
            case .off: stopPlayRing()
            }
        }
    }
    
    
    init(user: User) {
        self.user = user
        KeyManager.HostUserUID = "\(user.uid ?? 0)"
    }
    
    
    public var body: some View {
        VStack {
            NavigationLink(destination: videoCallView, isActive: $presentVideoCall) { }
            ProfileImage(frame: CGSize(width: 150, height: 150))
                .padding(.leading, 10)
                .padding(.top,60)
            Text(user.username ?? "")
                .font(.system(size: 50))
            Text("Calling...")
                .font(.system(size: 20))
            Spacer()
            
            Spacer()
            Button(action: toggleLocalSession) {
                Image(isLocalInSession ? "end" : "call")
                    .resizable()
            }.frame(width: 70, height: 70)
            Spacer()
        }.padding(.top,30)
            .onAppear {
                videoCallView.videoChatDelegate = self //call the VideoCallView
                callCenter.delegate = self
                AgoraRtm.shared().inviterDelegate = self
            }
    }
    
    mutating func startPlayRing() {
        let path = Bundle.main.path(forResource: "ring", ofType: "mp3")
        let url = URL.init(fileURLWithPath: path!)
        AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
        
        AudioServicesAddSystemSoundCompletion(soundId,
                                              CFRunLoopGetMain(),
                                              nil, { (soundId, context) in
                                                AudioServicesPlaySystemSound(soundId)
        }, nil)
        
        AudioServicesPlaySystemSound(soundId)
    }
    
    func stopPlayRing() {
        AudioServicesDisposeSystemSoundID(soundId)
        AudioServicesRemoveSystemSoundCompletion(soundId)
    }
}
////////////////////////////////////////////////////////////////////////////////////////
final class MyViewModel: ObservableObject, AgoraRtmInvitertDelegate {
   // @StateObject
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
        case .error:
            print(reason.description)
            break
        case .remoteReject(let remote):
            callCenter.endCall(of: remote)
            toggleLocalSession()
            print(reason.description + ": \(remote)")
        case .normaly(let remote):
            guard let inviter = AgoraRtm.shared().inviter else {
                fatalError("rtm inviter nil")
            }
            
            let errorHandle: ErrorCompletion = { (error: AGEError) in
                print(error.localizedDescription)
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
///////////////////////////////////////////////////////////////////////////////

/*
extension CallView: AgoraRtmInvitertDelegate {
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
        case .error:
            print(reason.description)
            break
        case .remoteReject(let remote):
            callCenter.endCall(of: remote)
            toggleLocalSession()
            print(reason.description + ": \(remote)")
        case .normaly(let remote):
            guard let inviter = AgoraRtm.shared().inviter else {
                fatalError("rtm inviter nil")
            }
            
            let errorHandle: ErrorCompletion = { (error: AGEError) in
                print(error.localizedDescription)
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
 */


extension CallView: CallCenterDelegate {
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

            print("KeyManager.HostUserUID2: " + KeyManager.HostUserUID)
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

extension CallView: VideoChatDelegate {
    func videoChat(didEndChatWith uid: String) {
        callCenter.endCall(of: uid)
    }

}


fileprivate extension CallView {
    func toggleLocalSession() {
        isLocalInSession.toggle()
        if isLocalInSession {
            callCenter.startOutgoingCall(of: KeyManager.HostUserUID)
        } else {
            callCenter.endCall(of: KeyManager.HostUserUID)
        }
    }
}

struct CallView_Previews: PreviewProvider {
    //@State static var user = User.current!
    @State static var user = User()
    
    static var previews: some View {
       CallView(user: user)
        //CallView()
    }
}


