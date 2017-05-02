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

    @IBOutlet weak var notification: NSTextField!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pipelineDown = false
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
    
    func checkStage(){
        
        self.showNotification(message: "Checking...")
        
        let url = URL(string: "https://gocd.thoughtworks.net/go/api/stages/SalesFunnel/Test/history")
        
        var request = URLRequest(url: url!)
        let username = self.username.stringValue
        let password = self.password.stringValue
        
        if username.isEmpty || password.isEmpty {
            self.showNotification(message: "username and password cannot be empty!")
            return
        }
        
        let loginString = NSString(format: "%@:%@", username, password)
        let loginData: NSData = loginString.data(using: String.Encoding.utf8.rawValue)! as NSData
        let base64LoginString = loginData.base64EncodedString()
        
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            let jsonString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            let data = jsonString?.data(using: String.Encoding.utf8.rawValue)!
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as? [String:Any] {
                    if let latestStage = json["stages"] as? [Any] {
                        let result = latestStage.first! as! [String: Any]
                        if (result["result"]! as! String) != "Passed"{
                            DispatchQueue.main.async {
                                self.showNotification(message: "Latest Test Failed! Go......")
                                if self.pipelineDown == false {
                                    self.playSound()
                                }
                                self.pipelineDown = true
                                
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.pipelineDown = false
                                self.showNotification(message: "Latest Test Passed!")
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
    
    func playSound() {
        let url = Bundle.main.url(forResource: "2107.王妃.萧敬腾.HD0761", withExtension: "mp3", subdirectory: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }

}

