import UIKit
import JitsiMeetSDK

class JitsiViewController: UIViewController {
    
    @IBOutlet weak var videoButton: UIButton?
    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    
    var eventSink:FlutterEventSink? = nil
    var roomName:String? = nil
    var serverUrl:URL? = nil
    var subject:String? = nil
    var audioOnly:Bool? = false
    var audioMuted: Bool? = false
    var videoMuted: Bool? = false
    var token:String? = nil
    var featureFlags: Dictionary<String, Bool>? = Dictionary();
    
    
    var jistiMeetUserInfo = JitsiMeetUserInfo()
    
    override func loadView() {
        
        super.loadView()
    }
    
    @objc func openButtonClicked(sender : UIButton){
        
        //openJitsiMeetWithOptions();
    }
    
    @objc func closeButtonClicked(sender : UIButton){
        cleanUp();
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        //print("VIEW DID LOAD")
        self.view.backgroundColor = .black
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        openJitsiMeet();
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
    }

    // This is needed to avoid the Flutter view behind it, to be hit by touch events.
    // See: 
    // https://github.com/flutter/flutter/issues/14720
    // https://github.com/flutter/flutter/issues/35784#issuecomment-516243057
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    func openJitsiMeet() {
        cleanUp()
        // create and configure jitsimeet view
        let jitsiMeetView = JitsiMeetView()
        
        
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = self.roomName
            builder.serverURL = self.serverUrl            
            builder.userInfo = self.jistiMeetUserInfo
            builder.token = self.token
            
            self.featureFlags?.forEach{ key,value in
                builder.setFeatureFlag(key, withValue: value);
            }
            builder.setAudioOnly(self.audioOnly!);
            builder.setAudioMuted(self.audioMuted!);
            builder.setVideoMuted(self.videoMuted!);
            builder.setSubject(self.subject!);
            
        }
        
        jitsiMeetView.join(options)
        
        // Enable jitsimeet view to be a view that can be displayed
        // on top of all the things, and let the coordinator to manage
        // the view state and interactions
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: view)
        
        // animate in
        jitsiMeetView.alpha = 0
        pipViewCoordinator?.show()
    }
    
    func closeJitsiMeeting(){
        jitsiMeetView?.leave()
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
        //self.dismiss(animated: true, completion: nil)
    }
}

extension JitsiViewController: JitsiMeetViewDelegate {
    
    func conferenceWillJoin(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE WILL JOIN")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceWillJoin", forKey: "event")
        self.eventSink?(mutatedData)
    }
    
    func conferenceJoined(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE JOINED")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceJoined", forKey: "event")
        self.eventSink?(mutatedData)
    }
    
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        //        print("CONFERENCE TERMINATED")
        var mutatedData = data
        mutatedData?.updateValue("onConferenceTerminated", forKey: "event")
        self.eventSink?(mutatedData)
        
        DispatchQueue.main.async {
            self.pipViewCoordinator?.hide() { _ in
                self.cleanUp()
                self.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        //        print("CONFERENCE PIP")\
        var mutatedData = data
        mutatedData?.updateValue("onPictureInPictureWillEnter", forKey: "event")
        self.eventSink?(mutatedData)
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }

    func exitPictureInPicture() {
        //        print("CONFERENCE PIP OUT")
        var mutatedData : [AnyHashable : Any]
        mutatedData = ["event":"onPictureInPictureTerminated"]
        self.eventSink?(mutatedData)
    }

    func onWhiteboardClicked() {
        //        print("CONFERENCE PIP OUT")
        var mutatedData : [AnyHashable : Any]
        mutatedData = ["event":"onWhiteboardClicked"]
        self.eventSink?(mutatedData)
    }
}


extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
