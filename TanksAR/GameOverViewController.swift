//
//  GameOverViewController.swift
//  TanksAR
//
//  Created by Bryan Franklin on 6/13/18.
//  Copyright © 2018-2019 Doing Science To Stuff. All rights reserved.
//
//   This Source Code Form is subject to the terms of the Mozilla Public
//   License, v. 2.0. If a copy of the MPL was not distributed with this
//   file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

class GameOverViewController: UIViewController, UITextFieldDelegate {
    
    var highScores: HighScoreController!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var playerNameStack: UIStackView!
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerScoreLabel: UILabel!
    @IBOutlet weak var playerNameField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    var currentPlayerID: Int = -1
    
    @IBOutlet weak var newHighSchoolLabel: UILabel!
    @IBOutlet weak var resultsStack: UIStackView!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var players: [Player] = []
    var nameAccepted: [Bool] = []
    var gameConfig: GameConfig = GameConfig()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // prepare for keyboard stuff:
        // see: https://stackoverflow.com/questions/26070242/move-view-with-keyboard-using-swift
        NotificationCenter.default.addObserver(self, selector: #selector(GameOverViewController.keyboardWasShown), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GameOverViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        // Do any additional setup after loading the view.
        highScores = HighScoreController()
        playerNameField.delegate = self
        nameAccepted = [Bool](repeating: false, count: players.count)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateUI()
    }

    // see: ScrollingForm example project (p.589)
    @objc func keyboardWasShown(_ notification: NSNotification) {
        guard let info = notification.userInfo,
            let keyboardFrameValue = info[UIKeyboardFrameBeginUserInfoKey] as? NSValue else { return }
        
        let keyboardFrame = keyboardFrameValue.cgRectValue
        let keyboardSize = keyboardFrame.size
        
        let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        
        // scroll to name field
        let nameFieldFrame = playerNameField.frame
        scrollView.setContentOffset(CGPoint(x: 0, y: nameFieldFrame.origin.y + 10), animated: true)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // see: https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    @IBAction func playerNameModified(_ sender: UITextField) {
        guard let newName = sender.text else { return }
        
        doneButton.isEnabled = checkName(newName)
    }
    
    func checkName(_ name: String) -> Bool {
        return name != ""
    }
    
    @IBAction func playerNameChanged(_ sender: UITextField) {
        NSLog("\(#function) started")
        if let newName = sender.text {
            NSLog("newName: \(newName)")
            if checkName(newName) {
                NSLog("newName \(newName) accepted by checkName")
                players[currentPlayerID].name = newName
                players[currentPlayerID].didSetName = true
                nameAccepted[currentPlayerID] = true
            }
        }
        updateUI()
        NSLog("\(#function) finished")
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        NSLog("done button pressed")
        nameAccepted[currentPlayerID] = checkName(players[currentPlayerID].name)
        updateUI()
    }
    
    func updateUI() {
        NSLog("\(#function) started")

        // check to see is any names need to be entered
        let scoreList = highScores.topScores(num: highScores.maxShown)
        let minScore = scoreList[highScores.maxShown-1].score
        for playerID in 0..<players.count {
            let player = players[playerID]
            
            if player.score > minScore && player.ai == nil {
                // human player got a high score
                playerNameStack.isHidden = false
                resultsStack.isHidden = true
                currentPlayerID = playerID

                playerNameLabel.text = player.name
                playerScoreLabel.text = "\(player.score)"
                playerNameField.resignFirstResponder()
                playerNameField.text = player.name

                if (!player.didSetName || player.name == "") {
                    // name is invalid
                    doneButton.isEnabled = false
                    NSLog("\(#function) finished early (line \(#line))")
                    return
                } else if !nameAccepted[playerID] {
                    // verify name
                    NSLog("nameAccepted[\(playerID)] = \(nameAccepted[playerID])")
                    doneButton.isEnabled = true
                    NSLog("\(#function) finished early (line \(#line))")
                    return
                }
            }
        }
        
        // record scores
        NSLog("Recording scores.")
        var winnerName: String = ""
        var winnerScore: Int64 = Int64.min
        for player in players {
            let score = HighScore(name: player.name,
                                  score: player.score,
                                  date: Date(),
                                  config: gameConfig,
                                  stats: player.stats)
            highScores.addHighScore(score: score)
            
            if score.score > winnerScore {
                winnerName = score.name
                winnerScore = score.score
            }
        }

        // if all names entered, show results
        NSLog("Showing game results.")
        playerNameStack.isHidden = true
        resultsStack.isHidden = false
        newHighSchoolLabel.isHidden = !(winnerScore > minScore)
        playerLabel.text = "\(winnerName) wins!"
        scoreLabel.text = "Score: \(winnerScore)"
        NSLog("\(#function) finished")
    }
    
    func reorderedNames() -> [String] {
        var ret: [String] = []
        
        // sort players by score (ascensing)
        let sortedPlayers = players.sorted(by: {a, b in
            if a.score < b.score {
                return true
            }
            return false
        })
        
        // add each human's name to a list
        for player in sortedPlayers {
            if player.ai == nil && player.name != "" {
                NSLog("Adding \(player.name) to playerNames (score=\(player.score))")
                if player.didSetName {
                    ret.append(player.name)
                } else {
                    ret.append("")
                }
            }
        }
        
        return ret
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let dest = segue.destination as? GameViewController {
            NSLog("Switching to game via \(segue.identifier!) segue.")
            if segue.identifier == "playAgain" {
                NSLog("\(#function) starting \(dest.gameConfig.numRounds) round game with \(dest.gameConfig.numHumans) humans and \(dest.gameConfig.numAIs) Als.")
                gameConfig.playerNames = reorderedNames()
                dest.gameConfig = gameConfig
                dest.gameModel = GameModel()
                //dest.gameModel = TestGameModel()    // for debugging
                dest.gameModel.gameOver = false
            } else {
                NSLog("Unknown segue identifier: \(segue.identifier!)")
            }
        }
    }

}
