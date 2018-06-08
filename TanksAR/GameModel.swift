//
//  GameModel.swift
//  TanksAR
//
//  Created by Bryan Franklin on 6/6/18.
//  Copyright © 2018 Doing Science To Stuff. All rights reserved.
//

// Note: Game model has the origin at one corner.

import Foundation
import UIKit
import SceneKit

struct Tank {
    var lon: Float
    var lat: Float
    var elev: Float
    var azimuth: Float // in degrees
    var altitude: Float // in degrees
    var velocity: Float
}

struct Player {
    var tank: Tank!
    var name: String = "Unknown"
    var score: Int64 = 0
}

struct GameBoard {
    var boardSize: Int = 0
    var surface: ImageBuf = ImageBuf()
    var bedrock: ImageBuf = ImageBuf()
    
    // vector to encode windspeed
    var wind: SCNVector3 = SCNVector3(0, 0, 0)
    
    // player
    var players: [Player] = []
    var currentPlayer: Int = 0
}

struct HighScore {
    var name: String = "Unknown"
    var score: Int64 = 0
}

struct FireResult {
    var trajectory: [SCNVector3] = []
    // need data to update map
}

// Note: For the model x,y are surface image coordinates, and z is elevation
// In GameViewController y and z are swapped.

class GameModel {
    // game board
    var board: GameBoard = GameBoard()
    
    // high-score data
    let highScores: [HighScore] = []
    
    func generateBoard() {
        board.boardSize = 1025
        board.surface.setSize(width: board.boardSize, height: board.boardSize)
        board.bedrock.setSize(width: board.boardSize, height: board.boardSize)
        
        board.surface.fillUsingDiamondSquare(withMinimum: 50.0/255.0, andMaximum: 200.0/255.0)
        board.bedrock.fillUsingDiamondSquare(withMinimum: 5.0/255.0, andMaximum: 40.0/255.0)
    }
    
    func startGame(numPlayers: Int) {
        board.players = [Player](repeating: Player(), count: numPlayers)
        board.currentPlayer = 0
        
        placeTanks()
    }
    
    func getElevation(longitude: Int, latitude: Int) -> Float {
        guard longitude >= 0 else { return -1 }
        guard longitude < board.boardSize else { return -1 }
        guard latitude >= 0 else { return -1 }
        guard latitude < board.boardSize else { return -1 }

        let (red: r, green: _, blue: _, alpha: _) = board.surface.getPixel(x: longitude, y: latitude)
        let elevation = Float(r*255)
        //print("Elevation at \(longitude),\(latitude) is \(elevation).")
        return elevation
    }
    
    func placeTanks(withMargin: Int = 50, minDist: Int = 10) {
        for i in 0..<board.players.count {
            let x = drand48() * Double(board.surface.width-withMargin*2) + Double(withMargin)
            let y = drand48() * Double(board.surface.height-withMargin*2) + Double(withMargin)

            let tankElevation = getElevation(longitude: Int(x), latitude: Int(y))
            board.players[i].tank = Tank(lon: Float(x), lat: Float(y), elev: Float(tankElevation),
                                         azimuth: 0, altitude: Float(Double.pi/4), velocity: 10)
        
            // flatten area around tanks
            let tank = board.players[i].tank!
            flattenAreaAt(longitude: Int(tank.lon), latitude: Int(tank.lat), withRadius: 100)
        }
    }
    
    func flattenAreaAt(longitude: Int, latitude: Int, withRadius: Int) {
        let min_x = (longitude<withRadius) ? 0 : longitude-withRadius
        let max_x = (longitude+withRadius>board.surface.width) ? 0 : longitude+withRadius
        let min_y = (latitude<withRadius) ? 0 : latitude-withRadius
        let max_y = (latitude+withRadius>board.surface.height) ? board.surface.height-1 : latitude+withRadius

        let elevation = getElevation(longitude: longitude, latitude: latitude)
        for j in min_y...max_y {
            for i in min_x...max_x {
                let xDiff = longitude - i
                let yDiff = latitude - j
                let dist = sqrt(Double(xDiff*xDiff + yDiff*yDiff))
                if( dist < Double(withRadius)) {
                    board.surface.setPixel(x: i, y: j, r: Double(elevation/255.0), g: 0, b: 0, a: 1.0)
                }
            }
        }
    }
    
    func getTank(forPlayer: Int) -> Tank {
        return board.players[forPlayer].tank
    }
    
    func setTankAim(azimuth: Float, altitude: Float) {
        var cleanAzimuth = azimuth
        if azimuth > 360 {
            let remove = Float(floor(cleanAzimuth/360)*360)
            cleanAzimuth -= remove
        } else if azimuth < 0 {
            cleanAzimuth = -cleanAzimuth
            let remove = Float(floor((cleanAzimuth)/360)*360)
            cleanAzimuth -= remove
            cleanAzimuth = 360 - cleanAzimuth
        }
        board.players[board.currentPlayer].tank.azimuth = cleanAzimuth
        board.players[board.currentPlayer].tank.altitude = max(0,min(altitude,180))
    }

    func setTankPower(power: Float) {
        guard power >= 0 else { return }

        board.players[board.currentPlayer].tank.velocity = power
    }

    func fire(muzzlePosition: SCNVector3, muzzleVelocity: SCNVector3) -> FireResult {
        print("Fire isn't fully implemented, yet!")
        board.currentPlayer = (board.currentPlayer + 1) % board.players.count
        print("Player \(board.currentPlayer) now active.")

        let timeStep = Float(1)/Float(10)
        let gravity = Float(9.80665)
        
        // compute trajectory
        var trajectory: [SCNVector3] = []
        var airborn = true
        var position = muzzlePosition
        var velocity = muzzleVelocity

        var iterCount = 0
        while airborn {
            //print("computing trajectory: pos=\(position), vel=\(velocity)")
            // record position
            trajectory.append(position)
            
            // update position
            position.x += velocity.x * timeStep
            position.y += velocity.y * timeStep
            position.z += velocity.z * timeStep

            // update velocity
            velocity.z -= 0.5 * gravity * (timeStep*timeStep)
            
            // check for impact
            let distAboveLand = position.z - getElevation(longitude: Int(position.x), latitude: Int(position.y))
            if position.y<0 || distAboveLand<0 {
                airborn = false
            }
            if iterCount > 10000 {
                break
            }
            iterCount += 1
            
            // deal with impact
        }
        
        let result: FireResult = FireResult(trajectory: trajectory)
        
        return result
    }
}
