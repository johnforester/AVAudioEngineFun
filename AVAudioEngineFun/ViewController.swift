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
    
    var delays: AVAudioUnitDelay[] = AVAudioUnitDelay[]()
    var generatorNodes: AVAudioNode[] = AVAudioNode[]()
    
    let updateTime: Float = 0.05
    
    var timer :NSTimer? = nil //set this in viewDidLoad
    
    @IBOutlet var filePlayerButton : UIButton
    @IBOutlet var filePlaySlider : UISlider
    
    @IBOutlet var delayTimeSlider : UISlider
    @IBOutlet var delayFeedbackSlider : UISlider
    
    @IBOutlet var micSwitch : UISwitch
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UI setup
        self.filePlaySlider.value = self.audioFilePlayer.volume
        
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
        
        self.generatorNodes.append(self.audioFilePlayer)
        
        //input setup
        self.generatorNodes.append(self.audioEngine.inputNode)
        
        //effects setup
        
        for node in self.generatorNodes
        {
            let delay = AVAudioUnitDelay()
            self.audioEngine.attachNode(delay)

            self.delays.append(delay)
            
            var format: AVAudioFormat? = nil
            
            if node == self.audioFilePlayer {
                format = file?.processingFormat
            } else if node == self.audioEngine.inputNode {
                format = self.audioEngine.inputNode.inputFormatForBus(0)
            }
         
            self.audioEngine.connect(node, to:delay, format:format)
            self.audioEngine.connect(delay, to: mixer, format: self.audioEngine.inputNode.inputFormatForBus(0))
        }

        var engineError: NSError?
        self.audioEngine.startAndReturnError(&engineError)
    
        
        //output tap
//        mixer.installTapOnBus(0, bufferSize: 512, format: file?.processingFormat, block:
//            {
//                (buffer: AVAudioPCMBuffer!,time: AVAudioTime!) -> Void in
//                
//                for (var j = 0; j < Int(buffer.format.channelCount); j++)
//                {
//                    var frames = buffer.floatChannelData[j]
//                    
//                    var frameLength = Int(buffer.frameLength)
//                    for (var i = 0; i < frameLength; i++)
//                    {
//                        //frames[i] do something with sample?
//                    }
//                }
//            })
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
    
    @IBAction func micSwitchChanged(micSwitch : UISwitch) {
        if micSwitch.on {
            self.audioEngine.inputNode.volume = 1
        } else {
            self.audioEngine.inputNode.volume = 0
        }
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
        //self.delay.feedback = self.delayFeedbackSlider.value
    }
    
    @IBAction func delayTimeSliderChanged(sender : AnyObject) {
        //self.delay.delayTime = NSTimeInterval(self.delayTimeSlider.value)
    }
}

