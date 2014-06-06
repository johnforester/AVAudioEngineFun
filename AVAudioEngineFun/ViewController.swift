//
//  ViewController.swift
//  AVAudioEngineFun
//
//  Created by John Forester on 6/5/14.
//  Copyright (c) 2014 John Forester. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

class ViewController: UIViewController {
    
    //MARK: - properties
    let audioEngine: AVAudioEngine = AVAudioEngine()
    let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    let delay: AVAudioUnitDelay = AVAudioUnitDelay()
    
    
    let updateTime: Float = 0.05
    
    var timer :NSTimer? = nil //set this in viewDidLoad
    
    @IBOutlet var filePlayerButton : UIButton
    @IBOutlet var filePlaySlider : UISlider
    
    @IBOutlet var delayTimeSlider : UISlider
    @IBOutlet var delayFeedbackSlider : UISlider
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UI setup
        self.filePlaySlider.value = self.audioFilePlayer.volume
        self.delayFeedbackSlider.value = self.delay.feedback
        self.delayTimeSlider.value = CFloat(self.delay.delayTime)
        
        //audio file
        let filePath: String = NSBundle.mainBundle().pathForResource("developers", ofType: "mp3")
        
        println("\(filePath)")
        
        let fileURL: NSURL = NSURL.URLWithString(filePath)
        
        var error: NSError?
        let file: AVAudioFile? = AVAudioFile(forReading: fileURL, error: &error)
        
        if let errorValue = error {
            println("ERROR: \(errorValue.localizedDescription)")
        }
        
        //player setup
        let mixer: AVAudioMixerNode = self.audioEngine.mainMixerNode
        
        self.audioEngine.attachNode(self.audioFilePlayer)
        self.audioFilePlayer.scheduleFile(file, atTime: nil, completionHandler:
            {
                println("done playing file")
            })
        
        //start engine
        var engineError: NSError?
        self.audioEngine.startAndReturnError(&engineError)
        
        //effects setup
        self.audioEngine.attachNode(self.delay)
        self.audioEngine.connect(self.audioFilePlayer, to:self.delay, format: file?.processingFormat)
        self.audioEngine.connect(self.delay, to: mixer, format: file?.processingFormat)
        
        //output tap
        mixer.installTapOnBus(0, bufferSize: 512, format: file?.processingFormat, block:
            {
                (buffer: AVAudioPCMBuffer!,time: AVAudioTime!) -> Void in
                
                for (var j = 0; j < Int(buffer.format.channelCount); j++)
                {
                    var frames = buffer.floatChannelData[j]
                    
                    var frameLength = Int(buffer.frameLength)
                    for (var i = 0; i < frameLength; i++)
                    {
                        //frames[i] do something with sample?
                    }
                }
            })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func refreshViews() {
        
        
    }
    
    @IBAction func filePlayerSliderChanged(sender : AnyObject) {
        self.audioFilePlayer.volume = self.filePlaySlider.value
    }
    
    //MARK: - IBAction methods
    @IBAction func playFileButtonPressed(sender : AnyObject) {
        if (self.audioFilePlayer.playing) {
            self.audioFilePlayer.pause()
            self.filePlayerButton.setTitle("play file", forState: .Normal)
        } else {
            self.audioFilePlayer.play()
            self.filePlayerButton.setTitle("pause", forState: .Normal)
        }
    }
    
    @IBAction func delayFeedbackSliderChanged(sender : AnyObject) {
        self.delay.feedback = self.delayFeedbackSlider.value
    }
    
    @IBAction func delayTimeSliderChanged(sender : AnyObject) {
        self.delay.delayTime = NSTimeInterval(self.delayTimeSlider.value)
    }
}

