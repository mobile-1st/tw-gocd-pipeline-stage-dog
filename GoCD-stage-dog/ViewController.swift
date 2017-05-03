//
//  ViewController.swift
//  GoCD-stage-dog
//
//  Created by Wei Sun on 02/05/2017.
//  Copyright © 2017 sunzhongmou. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    var player: AVAudioPlayer?
    var gameTimer: Timer!
    var pipelineDown: Bool!
    
    let gGoServerAPIUrl = "https://gocd.thoughtworks.net/go/api/stages/"
    let gPipelineName: String! = "SalesFunnel"
    let gWatchStages: [String] = ["Test"]
    let gTemember = [
        "jiangxu": "江江",
        "yren": "教主",
        "ywchen": "old fish",
        "tywang": "sky one",
        "yycao": "洋洋",
        "wjshu": "皮皮",
        "zhuang": "州州"
    ]

    @IBOutlet weak var notification: NSTextField!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    
    let synth = NSSpeechSynthesizer()
    func setupVoice() {
        synth.setVoice("com.apple.speech.synthesis.voice.ting-ting")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pipelineDown = false
        self.setupVoice()
        print(self.getCurrentTime())
    }
    
    @IBAction func onFire(_ sender: Any) {
        self.showNotification(message: "Ready, go...")
        
        self.invalidateTimer()
        
        gameTimer = Timer.scheduledTimer(
            timeInterval: 15,
            target: self,
            selector: #selector(checkStage),
            userInfo: nil,
            repeats: true)
    }
    
    func invalidateTimer() {
        if (gameTimer != nil) {
            gameTimer.invalidate()
        }
    }
    
    func showNotification(message: String) {
        notification.stringValue = message
    }
    
    func checkUserInfo() -> Bool {
        let username = self.username.stringValue
        let password = self.password.stringValue
        
        if username.isEmpty || password.isEmpty {
            self.showNotification(message: "username and password cannot be empty!")
            return false
        }
        
        return true
    }
    
    func checkStage(){
        
        self.showNotification(message: "Checking...")
        
        if self.checkUserInfo() == false { return }
        
        for name in gWatchStages {
            let stageRequest = self.buildRequest(stageName: name)
            self.fire(request: stageRequest)
        }
        
    }
    
    func getErrorMessage(name: String!) -> String {
        var errorMessage = ""
        
        if name == "changes" {
            errorMessage = "哪位少年又把派佩烂弄挂了，赛世方罗喊你修派佩烂啦"
        } else {
            let chineseName = gTemember[name]
            errorMessage = chineseName! + "，你又把派佩烂弄挂了，赛世方罗又喊你修派佩烂啦"
        }
        
        return errorMessage
    }
    
    func fire(request: URLRequest!) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let jsonString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            let data = jsonString?.data(using: String.Encoding.utf8.rawValue)!
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as? [String:Any] {
                    
                    
                    if let latestStage = json["stages"] as? [Any] {
                        let result = latestStage.first! as! [String: Any]
                        if (result["result"]! as! String) == "Failed"{
                            let approvalName = result["approved_by"] as! String
                            let errorMessage = self.getErrorMessage(name: approvalName)
                            
                            
                            
                            DispatchQueue.main.async {
                                self.showNotification(message: "Failed! " + self.getCurrentTime())
                                if self.pipelineDown == false {
                                    self.playSound()
                                    self.playVoice(textMessage: errorMessage)
                                }
                                self.pipelineDown = true
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.pipelineDown = false
                                self.showNotification(message: "Passed! " + self.getCurrentTime())
                            }
                        }
                    }
                }
            } catch let err{
                DispatchQueue.global().async {
                    print(err.localizedDescription)
                }
            }
        }
        task.resume()
    }
    
    func buildRequest(stageName: String!) -> URLRequest {
        let url = URL(string: "https://gocd.thoughtworks.net/go/api/stages/\(gPipelineName as String)/\(stageName as String)/history")
        
        var request = URLRequest(url: url!)
        let username = self.username.stringValue
        let password = self.password.stringValue
        
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
        let base64LoginString = loginData.base64EncodedString()
        
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    func playSound() {
        let url = Bundle.main.url(forResource: "ZH_TS", withExtension: "wav", subdirectory: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playVoice(textMessage: String!) {
        synth.startSpeaking(textMessage)
    }
    
    func getCurrentTime() -> String! {
        let date = Date()
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        return "\(year):\(month):\(day):\(hour):\(minutes):\(seconds)"
    }
}

