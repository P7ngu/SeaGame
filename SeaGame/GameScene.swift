//
//  GameScene.swift
//  SeaGame
//
//  Created by Matteo Perotta on 06/12/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate { //We add the contact delegate to dected collisions and send notifications when they happen, hence react to them happening
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
  
    private var spinnyNode : SKShapeNode?
    
    //Custom vars:
    let player = SKSpriteNode(imageNamed: "player-submarine")
    var touchingPlayer = false
    var gameTimer: Timer? //it's optional
    let scoreLabel = SKLabelNode(fontNamed: "AvenireNextCondensed-Bold")
    var score = 0 {
        //observer:
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    
    let music = SKAudioNode(fileNamed: "cyborg-ninja.mp3")
    
    override func sceneDidLoad() {
        scoreLabel.zPosition = 2
        scoreLabel.position.y = 125
        addChild(scoreLabel)
        score = 0
        //we use property observer to update the ui every time the value changes
        
        let background = SKSpriteNode(imageNamed: "water")
        background.zPosition = -1 //on top or below other sprites? that means behind all the others.
        addChild(background)
        
        if let particles = SKEmitterNode(fileNamed: "Bubbles"){
            particles.position.x = 512
            particles.advanceSimulationTime(10) //as soon as the game starts, 10 secs of particles
            addChild(particles)
        }
        
        player.position.x = -300
        player.zPosition = 1
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.categoryBitMask = 1 //For collision purpose, and collision detection, in the contact test mask
        //sprite.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        player.physicsBody?.linearDamping = .infinity // friction is useless in water, we use this to not make the player fall since the iphone is upside down
        
        physicsWorld.contactDelegate = self // to set to use the SKPh.ContactDelegate
        
        //SK gives you body A and body B, and if there is a series of collisions it becomes a problem, so we use the func didbegin and check if the node inside of the collision exists still -> did begin
        
       // gameTimer = Timer.scheduledTimer(timeInterval: 0.35, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
        
        addChild(music)
        
    }
    
    override func didMove(to view: SKView) {
        gameTimer = Timer.scheduledTimer(timeInterval: 1.8, target: self, selector: #selector(createEnemy), userInfo: nil, repeats: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        if tappedNodes.contains(player){
            touchingPlayer = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       // for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
        guard touchingPlayer else { return }
        guard let touch = touches.first else { return }
        
        let location  = touch.location(in: self)
        player.position = location
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       // for t in touches { self.touchUp(atPoint: t.location(in: self)) }
        touchingPlayer = false
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        //to remove the enemies off the screen
        for node in children {
            if node.position.y < -300 {
                node.removeFromParent()
            }
        }
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
     
        
        self.lastUpdateTime = currentTime
    }
    
    @objc func createEnemy(){
        let randomDistribution = GKRandomDistribution(lowestValue: -250, highestValue: 350) //random Y value for the enemy to spawn in
        let sprite = SKSpriteNode(imageNamed: "enemy")
        sprite.position = CGPoint(x: randomDistribution.nextInt(), y: 300)
        sprite.name = "enemy" //we can check on it later on
        sprite.zPosition = 1
        addChild(sprite)
        
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size) //add phys.
        //CG Vector uses X and Y differences from 0
        sprite.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        sprite.physicsBody?.linearDamping = 20 // friction is useless in water
        
        
        sprite.physicsBody?.contactTestBitMask = 1 //1 indicates the player, only collide with the player
        sprite.physicsBody?.categoryBitMask = 0 //so we can ignore their collision with one another.
        
        if player.parent != nil{
            //he's not dead
            score += 1
        }
        if randomDistribution.nextInt() % 2 == 0{
          
            createBonus()
        }
        
    }
    
    @objc func createBonus(){
        let randomDistribution = GKRandomDistribution(lowestValue: -250, highestValue: 350) //random Y value for the enemy to spawn in
        let sprite = SKSpriteNode(imageNamed: "fish")
        sprite.position = CGPoint(x: randomDistribution.nextInt(), y: 300)
        sprite.name = "bonus" //we can check on it later on
        sprite.zPosition = 1
        addChild(sprite)
        
        sprite.physicsBody = SKPhysicsBody(texture: sprite.texture!, size: sprite.size) //add phys.
        //CG Vector uses X and Y differences from 0
        sprite.physicsBody?.velocity = CGVector(dx: -500, dy: 0)
        sprite.physicsBody?.linearDamping = 20 // friction is useless in water
        
        
        sprite.physicsBody?.contactTestBitMask = 1 //1 indicates the player, only collide with the player
        sprite.physicsBody?.categoryBitMask = 0 //so we can ignore their collision with one another.
        sprite.physicsBody?.collisionBitMask = 0 //we get notified when the player touches the bonus, but they won't bounch on eachother
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player{
            playerHit(nodeB)
        } else {
            playerHit(nodeA)
        }
    }
    
    func playerHit(_ node: SKNode){
        
        let sound = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
        run(sound)
        
        if node.name == "bonus"{
            if player.parent != nil{
                //he's not dead
                score += 5
            }
            node.removeFromParent()
            return
        }
        if let particles = SKEmitterNode(fileNamed: "Explosion"){
            particles.position.x = player.position.x
            particles.position.y = player.position.y
            particles.zPosition = 3
            addChild(particles)
        }

        player.removeFromParent()
        music.removeFromParent()
        
        let gameOver = SKSpriteNode(imageNamed: "gameover")
        gameOver.zPosition = 10
        addChild(gameOver)
        
        //let's wait 2 seconds and then run some new code
        DispatchQueue.main.asyncAfter(deadline: .now()+2){
            //new scene incoming
            if let scene = GameScene(fileNamed: "GameScene"){
                scene.scaleMode = .aspectFill
                //let's present it immediately
                self.view?.presentScene(scene)
            }
        }
    }
}
