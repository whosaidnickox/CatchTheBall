//
//  GameViewController.swift
//  CatchTheBall
//
//  Created by Роман  on 17.03.2025.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Принудительно устанавливаем альбомную ориентацию
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        if let view = self.view as! SKView? {
            // Создаем загрузочную сцену с правильными размерами
            let screenSize = UIScreen.main.bounds.size
            let sceneSize = CGSize(width: max(screenSize.width, screenSize.height),
                                 height: min(screenSize.width, screenSize.height))
            let scene = LoadingScene(size: sceneSize)
            
            // Используем resizeFill для корректного масштабирования
            scene.scaleMode = .resizeFill
            
            // Настраиваем отображение
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            
            // Представляем сцену
            view.presentScene(scene)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
