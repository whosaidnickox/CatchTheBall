//
//  MainMenuScene.swift
//  CatchTheBall
//
//  Created by Роман  on 17.03.2025.
//

import SpriteKit

class MainMenuScene: SKScene {
    
    private var backgroundNode: SKSpriteNode?
    private var logoNode: SKSpriteNode?
    private var playButton: SKSpriteNode?
    private var settingsButton: SKSpriteNode?
    private var rulesButton: SKSpriteNode?
    private var settingsLabel: SKLabelNode?
    private var rulesLabel: SKLabelNode?
    
    override func sceneDidLoad() {
        setupBackground()
        setupLogo()
        setupButtons() // Теперь кнопки после лого, чтобы правильно позиционировать PLAY
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
        
        // Уменьшаем размер логотипа до 25% от ширины экрана
        let maxWidth = frame.width * 0.25
        let scale = maxWidth / logo.size.width
        logo.size = CGSize(width: maxWidth, height: logo.size.height * scale)
        
        // Позиционируем логотип в верхней части экрана, но с отступом
        logo.position = CGPoint(x: frame.midX, y: frame.height * 0.6)
        logo.zPosition = 1
        
        addChild(logo)
        self.logoNode = logo
    }
    
    private func setupButtons() {
        // Настраиваем кнопки SETTINGS и RULES
        let sideButtonWidth = frame.width * 0.08 // 8% от ширины экрана
        let topPadding = frame.height * 0.12 // увеличиваем отступ сверху
        
        // Настройки в левом верхнем углу
        let settingsButton = SKSpriteNode(imageNamed: "settings_button")
        let settingsScale = sideButtonWidth / settingsButton.size.width
        settingsButton.size = CGSize(width: sideButtonWidth, height: settingsButton.size.height * settingsScale)
        settingsButton.position = CGPoint(x: frame.width * 0.1, y: frame.height - topPadding)
        settingsButton.name = "settingsButton"
        settingsButton.zPosition = 2
        addChild(settingsButton)
        self.settingsButton = settingsButton
        
        // Добавляем текст "SETTINGS" под кнопкой настроек
        let settingsLabel = SKLabelNode(fontNamed: "Arial-Bold")
        settingsLabel.text = "SETTINGS"
        settingsLabel.fontSize = min(frame.width * 0.025, 14)
        settingsLabel.fontColor = .white
        settingsLabel.position = CGPoint(x: settingsButton.position.x,
                                       y: settingsButton.position.y - settingsButton.size.height/2 - 15)
        settingsLabel.zPosition = 2
        addChild(settingsLabel)
        self.settingsLabel = settingsLabel
        
        // Правила в правом верхнем углу
        let rulesButton = SKSpriteNode(imageNamed: "rules_button")
        let rulesScale = sideButtonWidth / rulesButton.size.width
        rulesButton.size = CGSize(width: sideButtonWidth, height: rulesButton.size.height * rulesScale)
        rulesButton.position = CGPoint(x: frame.width * 0.9, y: frame.height - topPadding)
        rulesButton.name = "rulesButton"
        rulesButton.zPosition = 2
        addChild(rulesButton)
        self.rulesButton = rulesButton
        
        // Добавляем текст "RULES" под кнопкой правил
        let rulesLabel = SKLabelNode(fontNamed: "Arial-Bold")
        rulesLabel.text = "RULES"
        rulesLabel.fontSize = min(frame.width * 0.025, 14)
        rulesLabel.fontColor = .white
        rulesLabel.position = CGPoint(x: rulesButton.position.x,
                                    y: rulesButton.position.y - rulesButton.size.height/2 - 15)
        rulesLabel.zPosition = 2
        addChild(rulesLabel)
        self.rulesLabel = rulesLabel
        
        // Настраиваем кнопку PLAY
        let playButton = SKSpriteNode(imageNamed: "play_button")
        let playButtonWidth = frame.width * 0.25 // 25% от ширины экрана
        let playButtonScale = playButtonWidth / playButton.size.width
        playButton.size = CGSize(width: playButtonWidth, height: playButton.size.height * playButtonScale)
        
        // Позиционируем кнопку PLAY относительно логотипа
        if let logo = self.logoNode {
            playButton.position = CGPoint(x: frame.midX, y: logo.position.y - logo.size.height * 0.8)
        } else {
            playButton.position = CGPoint(x: frame.midX, y: frame.height * 0.4)
        }
        
        playButton.name = "playButton"
        playButton.zPosition = 1
        addChild(playButton)
        self.playButton = playButton
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            switch node.name {
            case "playButton":
                handlePlayButton()
            case "settingsButton":
                handleSettingsButton()
            case "rulesButton":
                handleRulesButton()
            default:
                break
            }
        }
    }
    
    private func handlePlayButton() {
           // Анимация нажатия
           playButton?.run(SKAction.sequence([
               SKAction.scale(to: 0.9, duration: 0.1),
               SKAction.scale(to: 1.0, duration: 0.1)
           ]))
           
           // Переход к экрану выбора уровней
           let levelsScene = LevelsScene(size: self.size)
           levelsScene.scaleMode = .resizeFill
           
           let transition = SKTransition.fade(withDuration: 0.5)
           self.view?.presentScene(levelsScene, transition: transition)
       }
    
    private func handleSettingsButton() {
            // Анимация нажатия
            settingsButton?.run(SKAction.sequence([
                SKAction.scale(to: 0.9, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]))
            
            // Переход к экрану настроек
            let settingsScene = SettingsScene(size: self.size)
            settingsScene.scaleMode = .resizeFill
            
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(settingsScene, transition: transition)
        }
    
    private func handleRulesButton() {
        // Анимация нажатия
        rulesButton?.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        
        // Переход к экрану правил
        let rulesScene = RulesScene(size: self.size)
        rulesScene.scaleMode = .resizeFill
        
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(rulesScene, transition: transition)
    }
} 
