//
//  WeaponsViewController.swift
//  TanksAR
//
//  Created by Bryan Franklin on 6/11/18.
//  Copyright © 2018-2019 Doing Science To Stuff. All rights reserved.
//
//   This Source Code Form is subject to the terms of the Mozilla Public
//   License, v. 2.0. If a copy of the MPL was not distributed with this
//   file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit

class WeaponsViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playerNameField.delegate = self
        azimuthTextField.delegate = self
        altitudeTextField.delegate = self
        velocityTextField.delegate = self

        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    var gameModel: GameModel? = nil
    
    @IBOutlet weak var playerNameField: UITextField!
    @IBAction func playerNameChanged(_ sender: UITextField) {
        guard let model = gameModel else { return }
        let board = model.board
        let playerID = board.currentPlayer
        
        if let newName = sender.text {
            NSLog("new name: \(newName)")
            if newName.count <= 0 {
                model.board.players[playerID].name = "Player \(playerID+1)"
                model.board.players[playerID].didSetName = false
            } else {
                model.board.players[playerID].name = newName
                model.board.players[playerID].didSetName = true
            }
        } else {
            NSLog("new name missing!")
            model.board.players[playerID].name = "Player \(playerID+1)"
            model.board.players[playerID].didSetName = false
        }
        updateUI()
    }
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var creditLabel: UILabel!
    
    @IBOutlet weak var azimuthTextField: UITextField!
    @IBOutlet weak var altitudeTextField: UITextField!
    @IBOutlet weak var velocityTextField: UITextField!
    
    @IBOutlet weak var azimuthStepper: UIStepper!
    @IBOutlet weak var altitudeStepper: UIStepper!
    @IBOutlet weak var velocityStepper: UIStepper!
    
    @IBOutlet weak var targetComputerSwitch: UISwitch!
    
    // see: https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let str = textField.text else { return true }

        if str.last == "º" {
            textField.text = String(str.dropLast())
        } else if str.suffix(4) == " m/s" {
            textField.text = String(str.dropLast(4))
        }

        return true
    }
    
    @IBAction func valueChanged(_ sender: UITextField) {
        guard let str: String = sender.text else { return }
        NSLog("valueChanged to \(str)")
        guard let newValue = Double(str) else { return }

        // update model
        guard let model = gameModel else { return }
        guard model.board.currentPlayer < model.board.players.count else { return }
        let player = model.board.players[model.board.currentPlayer]
        
        if sender == azimuthTextField {
            model.setTankAim(azimuth: Float(newValue), altitude: player.tank.altitude)
        } else if sender == altitudeTextField {
            model.setTankAim(azimuth: player.tank.azimuth, altitude: Float(newValue))
        } else if sender == velocityTextField {
            model.setTankPower(power: Float(newValue))
        } else  {
            NSLog("\(#function): Unknown sender \(sender)")
        }
        
        // re-add degree symbol
        NSLog("new value: \(sender.text!)")
        
        updateUI()
    }
    
    @IBAction func aimStepperTapped(_ sender: UIStepper) {
        guard let model = gameModel else { return }
        let board = model.board
        let player = board.players[board.currentPlayer]
        let tank = player.tank
        
        // get current values
        var newAzimuth = tank.azimuth
        var newAltitude = tank.altitude
        var newVelocity = tank.velocity
        
        let newValue = Float(sender.value)
        NSLog("\(#function): stepper changed by \(newValue)")
        
        // update appropriate value
        if sender == azimuthStepper {
            newAzimuth = newValue
        } else if sender == altitudeStepper {
            newAltitude = newValue
        } else if sender == velocityStepper {
            newVelocity = newValue
        } else {
            NSLog("Unknown sender \(sender) to \(#function)")
        }
        
        // pass new values to models
        model.setTankAim(azimuth: newAzimuth, altitude: newAltitude)
        model.setTankPower(power: newVelocity)

        // update the display
        updateUI()
    }
    
    @IBAction func targetComputerToggled(_ sender: UISwitch) {
            guard let model = gameModel else { return }
            let board = model.board
        
            gameModel?.board.players[board.currentPlayer].useTargetingComputer = sender.isOn
            updateUI()
    }

    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var reasonLabel: UILabel!
    
    @IBOutlet weak var weaponTypeLabel: UILabel!
    @IBOutlet weak var weaponSizeLabel: UILabel!
    @IBOutlet weak var weaponCostLabel: UILabel!
    @IBOutlet weak var availablePointsLabel: UILabel!
    
    @IBOutlet weak var weaponTypeStepper: UIStepper!
    @IBOutlet weak var weaponSizeStepper: UIStepper!
    
    @IBAction func weaponTypeStepperTapped(_ sender: UIStepper) {
        NSLog("\(#function) called")
        guard let model = gameModel else { return }
        let board = model.board
        var players = board.players

        // update weapon id for player
        let weaponID = Int(sender.value)
        let playerID = board.currentPlayer
        model.board.players[playerID].weaponID = weaponID
        model.board.players[playerID].weaponSizeID = min(players[playerID].weaponSizeID,
                                                         model.weaponsList[weaponID].sizes.count-1)
        NSLog("weapon now \(weaponID)")
        NSLog("weapon size now \(model.board.players[playerID].weaponSizeID)")

        // update size stepper options
        weaponSizeStepper.maximumValue = Double(model.weaponsList[weaponID].sizes.count-1)
        weaponSizeStepper.stepValue = Double(1)

        updateUI()
    }
    
    @IBAction func weaponSizeStepperTapped(_ sender: UIStepper) {
        NSLog("\(#function) called")
        guard let model = gameModel else { return }
        let board = model.board

        // update size ID for player
        let weaponSizeID = Int(sender.value)
        model.board.players[board.currentPlayer].weaponSizeID = weaponSizeID
        NSLog("weapon size now \(weaponSizeID)")

        updateUI()
    }
    
    func updateUI() {
        guard let model = gameModel else { return }
        let board = model.board
        var players = board.players
        let playerID = board.currentPlayer
        let player = players[playerID]
        let tank = player.tank
        let weaponID = player.weaponID
        let weapon = model.weaponsList[weaponID]
        let weaponSize = weapon.sizes[player.weaponSizeID]

        // update score label
        scoreLabel.text = "Score: \(player.score)"
        creditLabel.text = "Credit: \(player.credit)"
        
        // update name
        playerNameField.text = board.players[playerID].name
        
        // update aiming information
        velocityStepper.minimumValue = 0
        velocityStepper.maximumValue = Double(model.maxPower)
        azimuthStepper.value = Double(tank.azimuth)
        altitudeStepper.value = Double(tank.altitude)
        velocityStepper.value = Double(tank.velocity)
        azimuthTextField.text = "\(tank.azimuth)º"
        altitudeTextField.text = "\(tank.altitude)º"
        velocityTextField.text = "\(tank.velocity) m/s"
        NSLog("aim: \(azimuthTextField.text!),\(altitudeTextField.text!) @ \(velocityTextField.text!)")

        // targeting computer switch
        targetComputerSwitch.isOn = player.useTargetingComputer
        let computerCost = model.computerCost

        // update limits on steppers
        weaponTypeStepper.minimumValue = 0
        weaponTypeStepper.maximumValue = Double(model.weaponsList.count) - 1
        weaponTypeStepper.stepValue = Double(1)
        weaponTypeStepper.value = Double(weaponID)
        weaponSizeStepper.minimumValue = 0
        weaponSizeStepper.maximumValue = Double(model.weaponsList[weaponID].sizes.count) - 1
        weaponSizeStepper.stepValue = Double(1)
        weaponSizeStepper.value = Double(player.weaponSizeID)

        // update labels
        NSLog("weapon name: \(weapon.name), size: \(weaponSize.name), cost: \(weaponSize.cost)")
        weaponTypeLabel.text = weapon.name
        weaponSizeLabel.text = weaponSize.name
        let shotCost = weaponSize.cost + ((player.useTargetingComputer || player.usedComputer) ? computerCost : 0)
        weaponCostLabel.text = "\(shotCost) points"
        availablePointsLabel.text = "\(player.credit + player.score) points"
        weaponCostLabel.textColor = UIColor.black
        
        // disable done button and give a reason if weapon is invalid
        doneButton.isEnabled = true
        reasonLabel.isHidden = true
        if (weaponID > 0 || player.useTargetingComputer || player.usedComputer) && shotCost > (player.credit + player.score) {
            reasonLabel.text = "Insufficient points for selected weapon!"
            reasonLabel.isHidden = false
            weaponCostLabel.textColor = UIColor.red
            doneButton.isEnabled = false
        }
        
        if  weaponSizeStepper.maximumValue < 2 {
            weaponSizeLabel.text = "N/A"
            weaponSizeStepper.isEnabled = false
        } else {
            weaponSizeStepper.isEnabled = true
        }
    }
}
