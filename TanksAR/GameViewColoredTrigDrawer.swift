//
//  GameViewColoredTrigDrawer.swift
//  TanksAR
//
//  Created by Bryan Franklin on 7/12/18.
//  Copyright © 2018-2019 Doing Science To Stuff. All rights reserved.
//
//   This Source Code Form is subject to the terms of the Mozilla Public
//   License, v. 2.0. If a copy of the MPL was not distributed with this
//   file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SceneKit

class GameViewColoredTrigDrawer : GameViewTrigDrawer {
    
    let colors = [UIColor.green, UIColor.brown, UIColor.gray]
    
    override func updateBoard() {
        NSLog("\(#function) started")
        
        // (re)create surface
        surface.removeFromParentNode()
        surface = surfaceNode(forSurface: gameModel.board.surface, useNormals: false, withColors: gameModel.board.colors, colors: colors)
        board.addChildNode(surface)
        
        // (re)create edges
        edgeNode.removeFromParentNode()
        let edgeShape = edgeGeometry(forSurface: gameModel.board.surface)
        edgeNode = SCNNode(geometry: edgeShape)
        board.addChildNode(edgeNode)
        
        // remove any temporary animation objects
        droppingNode.isHidden = true
        droppingNode.removeFromParentNode()
        droppingNode = SCNNode()
        if let morpher = surface.morpher {
            morpher.targets = [surface.geometry!]
        }
        
        newBottomSurface.removeFromParentNode()
        fluidNode.removeFromParentNode()
        
        NSLog("\(#function) finished")
    }
    
    override func animateResult(fireResult: FireResult, from: GameViewController) {
        super.animateResult(fireResult: fireResult, from: from, useNormals: false, colors: colors)
    }
    
}
