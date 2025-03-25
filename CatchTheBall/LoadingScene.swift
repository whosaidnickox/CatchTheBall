//
//  LoadingScene.swift
//  CatchTheBall
//
//  Created by Роман  on 17.03.2025.
//

import SpriteKit

class LoadingScene: SKScene {
    
    private var loadingLabel: SKLabelNode?
    private var backgroundNode: SKSpriteNode?
    private var logoNode: SKSpriteNode?
    
    override func sceneDidLoad() {
        setupBackground()
        setupLogo()
        setupLoadingText()
        
        // Переход к главному меню через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.switchToMainMenu()
        }
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Масштабируем фон, чтобы он полностью покрывал экран
        let scale = max(frame.width / background.size.width,
                       frame.height / background.size.height)
        background.size = CGSize(width: background.size.width * scale,
                               height: background.size.height * scale)
        
        background.zPosition = -1
        addChild(background)
        self.backgroundNode = background
    }
    
    private func setupLogo() {
        let logo = SKSpriteNode(imageNamed: "logo")
        
        // Уменьшаем размер логотипа до 35% от ширины экрана
        let maxWidth = frame.width * 0.35
        let scale = maxWidth / logo.size.width
        logo.size = CGSize(width: maxWidth, height: logo.size.height * scale)
        
        // Позиционируем логотип чуть выше центра
        logo.position = CGPoint(x: frame.midX, y: frame.midY + logo.size.height * 0.1)
        
        addChild(logo)
        self.logoNode = logo
    }
    
    private func setupLoadingText() {
        let loading = SKLabelNode(fontNamed: "Arial-Bold")
        loading.text = "LOADING..."
        loading.fontSize = min(frame.width * 0.03, 18) // Уменьшаем размер текста
        loading.fontColor = .white
        
        // Располагаем текст прямо под логотипом
        if let logo = self.logoNode {
            loading.position = CGPoint(x: frame.midX, y: logo.position.y - logo.size.height * 0.7)
        }
        loading.alpha = 0.7 // Делаем чуть более прозрачным
        addChild(loading)
        self.loadingLabel = loading
        
        // Добавляем анимацию мигания
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.8)
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.8)
        let sequence = SKAction.sequence([fadeOut, fadeIn])
        loading.run(SKAction.repeatForever(sequence))
    }
    
    private func switchToMainMenu() {
        let mainMenu = MainMenuScene(size: self.size)
        mainMenu.scaleMode = .resizeFill
        
        // Переход с затуханием
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(mainMenu, transition: transition)
    }
} 
