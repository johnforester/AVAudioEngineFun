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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - properties
    let audioEngine: AVAudioEngine = AVAudioEngine()
    let audioFilePlayer: AVAudioPlayerNode = AVAudioPlayerNode()
    var audioFile: AVAudioFile? = nil
    
    var delays: AVAudioUnitDelay[] = AVAudioUnitDelay[]()
    let delayTimeTag: Int = 100
    let delayFeedbackTag: Int = 200
    let delayOnOffTag: Int = 500
    
    var pitches: AVAudioUnitTimePitch[] = AVAudioUnitTimePitch[]()
    let pitchPitchTag: Int = 300
    let pitchRateTag: Int = 400
    
    var distortions: AVAudioUnitDistortion[] = AVAudioUnitDistortion[]()
    var distortionPresets = [
        "DrumsBitBrush",
        "DrumsBufferBeats",
        "DrumsLoFi",
        "MultiBrokenSpeaker",
        "MultiCellphoneConcert",
        "MultiDecimated1",
        "MultiDecimated2",
        "MultiDecimated3",
        "MultiDecimated4",
        "MultiDistortedFunk",
        "MultiDistortedCubed",
        "MultiDistortedSquared",
        "MultiEcho1",
        "MultiEcho2",
        "MultiEchoTight1",
        "MultiEchoTight2",
        "MultiEverythingIsBroken",
        "SpeechAlienChatter",
        "SpeechCosmicInterference",
        "SpeechGoldenPi",
        "SpeechRadioTower",
        "SpeechWaves",
    ]
    
    let sampler: AVAudioUnitSampler = AVAudioUnitSampler()
    var samplerNote: Int = 50
    
    var generatorNodes: AVAudioNode[] = AVAudioNode[]()
    
    let updateTime: Float = 0.05
    
    var timer :NSTimer? = nil //set this in viewDidLoad
    
    
    @IBOutlet var filePlayerButton : UIButton
    @IBOutlet var filePlaySlider : UISlider
    
    @IBOutlet var micSwitch : UISwitch
    @IBOutlet var outputMeter : UIProgressView
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.filePlaySlider.value = self.audioFilePlayer.volume
        
        //audio file
        let filePath: String = NSBundle.mainBundle().pathForResource("developers", ofType: "aif")
        
        println("\(filePath)")
        
        let fileURL: NSURL = NSURL.URLWithString(filePath)
        
        var error: NSError?
        self.audioFile = AVAudioFile(forReading: fileURL, error: &error)
        
        if let errorValue = error {
            println("ERROR: \(errorValue.localizedDescription)")
        }
        
        //player setup
        
        self.audioEngine.attachNode(self.audioFilePlayer)
        self.generatorNodes.append(self.audioFilePlayer)
        
        //input setup
        self.audioEngine.inputNode.volume = 0
        self.generatorNodes.append(self.audioEngine.inputNode)
        
        //sampler setup
        var samplerError: NSError?
        
        let samplerFilePath: String = NSBundle.mainBundle().pathForResource("developersSingle", ofType: "aif")
        
        
        let sampleURL: NSURL = NSURL.URLWithString(samplerFilePath)
        
        let sampleURLS: AnyObject[]! = [sampleURL]
        self.sampler.loadAudioFilesAtURLs(sampleURLS, error: &samplerError)
        self.audioEngine.attachNode(self.sampler)
        self.generatorNodes.append(self.sampler)
        
        
        // tap
        self.audioEngine.mainMixerNode.installTapOnBus(0, bufferSize: 8192, format: nil, block:
            {
                (buffer: AVAudioPCMBuffer!,time: AVAudioTime!) -> Void in
                
                for (var j = 0; j < Int(buffer.format.channelCount); j++)
                {
                    var frames = buffer.floatChannelData[j]
                    
                    var frameLength = Int(buffer.frameLength)
                    
                    for (var i = 0; i < frameLength; i++)
                    {
                        if (i % 1000 == 0) {
                            //println("\(frames[i])")
                            dispatch_async(dispatch_get_main_queue(), {
                                self.outputMeter.progress = fabsf(frames[i])
                            })
                        }
                    }
                }
                
            })
        
        //effects setup
        
        let mixer: AVAudioMixerNode = self.audioEngine.mainMixerNode
        
        for node in self.generatorNodes
        {
            let delay = AVAudioUnitDelay()
            self.audioEngine.attachNode(delay)
            self.delays.append(delay)
            
            let distortion = AVAudioUnitDistortion()
            self.audioEngine.attachNode(distortion)
            self.distortions.append(distortion)
            
            var format: AVAudioFormat? = nil
            
            if node == self.audioFilePlayer {
                format = self.audioFile?.processingFormat
                
                let timePitch = AVAudioUnitTimePitch()
                self.audioEngine.attachNode(timePitch)
                
                self.pitches.append(timePitch)
                
                self.audioEngine.connect(node, to:timePitch, format:format)
                self.audioEngine.connect(timePitch, to: distortion, format: format)
                self.audioEngine.connect(distortion, to: delay, format: format)
                self.audioEngine.connect(delay, to: mixer, format: format)
            } else if node == self.audioEngine.inputNode{
                format = self.audioEngine.inputNode.inputFormatForBus(0)
                self.audioEngine.connect(node, to: distortion, format: format)
                self.audioEngine.connect(distortion, to: delay, format: format)
            } else {
                format = self.audioEngine.inputNode.inputFormatForBus(0)
                self.audioEngine.connect(node, to: delay, format: format)
            }
            
            self.audioEngine.connect(delay, to: mixer, format: format)
        }
        
        for (var i = 0; i < self.delays.count; i++)
        {
            let delay: AVAudioUnitDelay = self.delays[i]
            
            let slider: UISlider? = self.view.viewWithTag(self.delayTimeTag + i) as? UISlider
            
            if let timeSlider = slider {
                timeSlider.value = CFloat(delay.delayTime)
            }
            
            let slider2: UISlider? = self.view.viewWithTag(self.delayFeedbackTag + i) as? UISlider
            
            if let feedbackSlider = slider2 {
                feedbackSlider.value = CFloat(delay.feedback)
            }
        }
        
        for (var i = 0; i < self.pitches.count; i++)
        {
            let pitch: AVAudioUnitTimePitch = self.pitches[i]
            
            let pitchSlider: UISlider = self.view.viewWithTag(self.pitchPitchTag + i) as UISlider
            pitchSlider.value = pitch.pitch
            
            let rateSlider: UISlider = self.view.viewWithTag(self.pitchRateTag + i) as UISlider
            rateSlider.value = pitch.rate
        }
        
        var engineError: NSError?
        self.audioEngine.startAndReturnError(&engineError)
        
        if engineError != nil {
            println("Error: \(engineError)")
        }
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
            self.audioFilePlayer.scheduleFile(self.audioFile, atTime: nil, completionHandler:
                {
                    println("done playing file")
                    self.filePlayerButton.setTitle("pause", forState: .Normal)
                })
            self.audioFilePlayer.play()
            self.filePlayerButton.setTitle("pause", forState: .Normal)
        }
    }
    
    @IBAction func delayFeedbackSliderChanged(slider : UISlider) {
        let delay: AVAudioUnitDelay = self.delays[slider.tag - self.delayFeedbackTag]
        delay.feedback = slider.value
    }
    
    @IBAction func delayTimeSliderChanged(slider : UISlider) {
        let delay: AVAudioUnitDelay = self.delays[slider.tag - self.delayTimeTag]
        delay.delayTime = NSTimeInterval(slider.value)
    }
    
    @IBAction func pitchSliderChanged(slider : UISlider) {
        let pitch: AVAudioUnitTimePitch = self.pitches[slider.tag - self.pitchPitchTag]
        pitch.pitch = slider.value
    }
    
    @IBAction func rateSliderChanged(slider : UISlider) {
        let pitch: AVAudioUnitTimePitch = self.pitches[slider.tag - self.pitchRateTag]
        pitch.rate = slider.value
    }
    
    @IBAction func delayOnOffChanged(delaySwitch : UISwitch) {
        let delay: AVAudioUnitDelay = self.delays[delaySwitch.tag]
        
        if (delaySwitch.on) {
            delay.wetDryMix = 100
        } else {
            delay.wetDryMix = 0
        }
    }
    
    @IBAction func distortionOnOffChanged(distSwitch : UISwitch) {
        let distortion = self.distortions[distSwitch.tag]
        
        if distSwitch.on {
            distortion.wetDryMix = 50
        } else {
            distortion.wetDryMix = 0
        }
    }
    
    @IBAction func samplerButtonPressed(sender : AnyObject) {
        self.sampler.startNote(UInt8(self.samplerNote), withVelocity: 127, onChannel: 1)
    }
    
    @IBAction func noteSliderChanged(slider : UISlider) {
        self.samplerNote = Int(slider.value)
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.distortionPresets.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("DistortionCell") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "DistortionCell")
        }
        
        cell!.textLabel.text = self.distortionPresets[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let distortion = self.distortions[tableView.tag]
        distortion.loadFactoryPreset(AVAudioUnitDistortionPreset.fromRaw(indexPath.row)!)
    }
    
}

