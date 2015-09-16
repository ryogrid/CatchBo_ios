//
//  ViewController.swift
//  DCatch
//
//  Created by Ryo Kanbayashi on 2015/09/14.
//  Copyright (c) 2015年 ryo_grid. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AVFoundation
import CoreMotion

class ViewController: UIViewController, MCBrowserViewControllerDelegate,
MCSessionDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var debugLabel: UILabel!
    
    let serviceType = "LCOC-Chat"
    
    var browser : MCBrowserViewController!
    var assistant : MCAdvertiserAssistant!
    var session : MCSession!
    var peerID: MCPeerID!
    var audioPlayer: AVAudioPlayer!
    var audioPlayer2: AVAudioPlayer!
    
    var currentOrientationValuesZ : Double = 0
    var currentAccelerationValuesZ : Double = 0
    
    var manager = CMMotionManager()
    var waitCounter = 0
    
    //    @IBOutlet var chatView: UITextView!
//    @IBOutlet var messageField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: peerID)
        self.session.delegate = self
        
        // create the browser viewcontroller with a unique service name
        self.browser = MCBrowserViewController(serviceType:serviceType,
            session:self.session)
        
        self.browser.delegate = self;
        
        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
            discoveryInfo:nil, session:self.session)
        
        // tell the assistant to start advertising our fabulous chat
        self.assistant.start()
        
        var sound_data = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("throw", ofType: "mp3")!)
        audioPlayer = AVAudioPlayer(contentsOfURL: sound_data, error: nil)
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        
        var sound_data2 = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("catch", ofType: "mp3")!)
        audioPlayer2 = AVAudioPlayer(contentsOfURL: sound_data2, error: nil)
        audioPlayer2.delegate = self
        audioPlayer2.prepareToPlay()
        

        //取得の間隔
        manager.accelerometerUpdateInterval = 0.1;
        let handler:CMAccelerometerHandler = {(data:CMAccelerometerData!, error:NSError!) -> Void in
            self.currentOrientationValuesZ = data.acceleration.z * 0.1 + self.currentOrientationValuesZ * 0.9
            self.currentAccelerationValuesZ = data.acceleration.z - self.currentOrientationValuesZ
    
 //           self.debugLabel.text = self.currentAccelerationValuesZ.description
            if self.currentAccelerationValuesZ > 0.5 && self.waitCounter > 10 {
                self.sendChat()
                self.waitCounter = 0
            }
            self.waitCounter++
        }
        
        //取得開始
        manager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:handler)
    }
    
//    @IBAction func sendChat(sender: UIButton) {
    func sendChat() {
        // Bundle up the text in the message field, and send it off to all
        // connected peers
        audioPlayer.play()
        audioPlayer.prepareToPlay()
        
//        let msg = self.messageField.text.dataUsingEncoding(NSUTF8StringEncoding,
//            allowLossyConversion: false)

        let between : Double = 2.5
        let msg = (between.description as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        var error : NSError?
        
        self.session.sendData(msg, toPeers: self.session.connectedPeers,
            withMode: MCSessionSendDataMode.Unreliable, error: &error)
        
        if error != nil {
            print("Error sending data: \(error?.localizedDescription)")
        }
        
//        self.updateChat(self.messageField.text, fromPeer: self.peerID)
        
//        self.messageField.text = ""
        
        NSThread.sleepForTimeInterval(between)
        
        audioPlayer2.play()
        audioPlayer2.prepareToPlay()
    }
    
    func updateChat(text : String, fromPeer peerID: MCPeerID) {
        // Appends some text to the chat view
        
        // If this peer ID is the local device's peer ID, then show the name
        // as "Me"
        var name : String
        
        switch peerID {
        case self.peerID:
            name = "Me"
        default:
            name = peerID.displayName
        }
        
        // Add the name to the message and display it
//        let message = "\(name): \(text)\n"
//        self.chatView.text = self.chatView.text + message
        
    }
    
    @IBAction func showBrowser(sender: UIButton) {
        // Show the browser view controller
        self.presentViewController(self.browser, animated: true, completion: nil)
    }
    
    func browserViewControllerDidFinish(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is dismissed (ie the Done
            // button was tapped)
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(
        browserViewController: MCBrowserViewController!)  {
            // Called when the browser view controller is cancelled
            
            self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!,
        fromPeer peerID: MCPeerID!)  {
            // Called when a peer sends an NSData to us
            
            // This needs to run on the main queue
            dispatch_async(dispatch_get_main_queue()) {
                
                var msg = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                self.updateChat(msg as! String, fromPeer: peerID)
                
                var between : Double? = msg?.doubleValue
                
                NSThread.sleepForTimeInterval(between!)
                
                self.audioPlayer2.play()
                self.audioPlayer2.prepareToPlay()
            }
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(session: MCSession!,
        didStartReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!)  {
            
            // Called when a peer starts sending a file to us
    }
    
    func session(session: MCSession!,
        didFinishReceivingResourceWithName resourceName: String!,
        fromPeer peerID: MCPeerID!,
        atURL localURL: NSURL!, withError error: NSError!)  {
            // Called when a file has finished transferring from another peer
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!,
        withName streamName: String!, fromPeer peerID: MCPeerID!)  {
            // Called when a peer establishes a stream with us
    }
    
    func session(session: MCSession!, peer peerID: MCPeerID!,
        didChangeState state: MCSessionState)  {
            // Called when a connected peer changes state (for example, goes offline)
            
    }
    
}

