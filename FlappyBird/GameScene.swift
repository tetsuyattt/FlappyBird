//
//  GameScene.swift
//  FlappyBird
//
//  Created by 富樫　哲也 on 2023/06/14.
//

import UIKit
import SpriteKit //追加２　ここでも、SKSceneを使うためにSpriteKitのimportが必須
import AVFoundation //追加(課題７？）効果音用　→４６行目へ　→４８２行目へ

class GameScene: SKScene,SKPhysicsContactDelegate {
    //追加１０　SKPhysicsContactDelegateプロトコルを追加して、SKPhysicsWorldクラスのcontactDelegateプロパティに設定
    //物理体が何かしら接触した時に応答を設定するメソッド。衝突判定をつけてる
    
    var scrollNode:SKNode!   //←追加５ 地面と雲をスクロールするためのもの
    var wallNode:SKNode!   //←追加７　壁をスクロールするためのもの
    var bird:SKSpriteNode! //←追加８ 鳥
    
    //追加（課題２）
    //    var heart:SKSpriteNode!だった
    var heartNode:SKNode!
    
    //ここから追加１０　衝突判定カテゴリー　衝突判定のためのIDってこと
    let birdCategory: UInt32 = 1 << 0   //0...00001
    let groundCategory: UInt32 = 1 << 1 //0...00010
    let wallCategory: UInt32 = 1 << 2   //0...00100
    let scoreCategory: UInt32 = 1 << 3  //0...01000 //　scoreCategory=スコアカウント用の透明な壁のことで、ここに接触した時に当たったと判定してスコアをカウントアップする
    //追加(課題)　ハートの衝突判定用
    let heartScoreCategory: UInt32 = 1 << 4
    
    //---------------------------スコア用
    var score = 0
    var itemScore = 0 //追加(課題６？くらい)
    var itemScoreLabelNode:SKLabelNode! //追加(課題６？くらい)
    //ここまで追加１０　衝突判定カテゴリー　次はfunc didMove
    
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    
    //追加１４　スコア保存には「UserDefaults」クラスの「UserDefaults.standard」プロパティでUserDefaultsを取得する
    //Realmみたいなデータベースを使う必要はない
    let userDefaults:UserDefaults = UserDefaults.standard   //スコア用の
    //---------------------------スコア用
    
    //ここから追加(課題７）効果音設定
//----------------------------------
    var musicPlayer: AVAudioPlayer!
    let effectSoundData = NSDataAsset(name: "powerup02")!.data
    func playEffectSound(){
//        do{
            musicPlayer = try? AVAudioPlayer(data: effectSoundData)
            musicPlayer.volume = 0.1
            musicPlayer.play()
//        }catch{
//            print("再生に失敗しました")
//        }
    }
    //ここまで追加(課題)効果音追加　→４８２行目へ

    
    //--------------ここから追加９　画面をタップした時に鳥を動かす　→追加１３にて編集
    //GameSceneクラスのtouchesBegan（）メソッド
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {      //追加１３　スクロールスピードが０より大きい時（＝ゲーム中の時だけって意味。こうしないとゲームオーバーの時も反応する）、
            //鳥の速度を０にする　velocity=速度　vector=ベクトル
            bird.physicsBody?.velocity = CGVector.zero
            //鳥に縦方向の力を加える impulse=衝動、勢い、弾み
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 { //追加１３ 鳥のスピードが０ならリスタートね、ってこと
            restart()
        }
    }
    //--------------ここまで追加９
    
    
    
    //-------------ここから追加４　SKScene上（ゲーム画面）にシーンが表示された時に呼ばれるメソッド　→画像の構築などの初期設定をする
    override func didMove(to view: SKView) {
        //追加６　地面とか雲の動きとかを全部一つのdidMoveメソッドに入れると長くなるしどれがどれかわからなくなるので、setupGround()とsetupCloud()のメソッドに分ける
        
        //↓追加８　重力を設定　→ここの数字あとでいじってみたい　次はfunc setupBirdのとこ
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self //←追加１０　複数の物理体が接触した時に呼ばれるデリゲート
        
        
        // 背景色の設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //追加５ スクロールするスプライトの親ノード（scrollNode） →ゲームオーバーになったらスクロールを一括で止められるようになる →なんで？？
        //このノード自体は画面に表示されないためSKSpriteクラスではなくNodeSKNodeクラスを使う
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //追加７　壁用のノード　上のと同じ
        wallNode = SKNode()
        addChild(wallNode)
        
        //追加（課題６？）最初これがなかった→「Thread 1: Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value」nilが検出されたとエラーがあった　→これ入れたら起動できた
        heartNode = SKNode()
        addChild(heartNode)
        
        //↓↓追加６　各スプライトを生成する処理をメソッドに分割した方が後々編集するときにどこに何があるかわかりやすいからおすすめ
        setupGround()
        setupCloud()
        
        setupWall()        //←追加７　次はfunc setupWall()
        setupBird()        //←追加８　次はfunc setupBird()
        setupScoreLabel()  //←追加１４（２）　ベストスコア表示
        
        //追加（課題１）　次はfunc setupHeart()作る　ランダムに出現させたいからまずはsetupWall()を参考にしてみる→１９８行目へ
        setupHeart()
    }
    
    
    
    //追加６　これまで作った地面の初期設定をsetupGround()と定義　→次はfunc setupClloudのとこ
    func setupGround() {
        //地面の画像を読み込む「"ground"ってやつをSKSceneで扱うからgroundTextureに持ってきてね」ってこと
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //↑SKTextureクラスのfilteringModeプロパティに.nearestと設定　→処理速度を高めるため
        //※ .nearest=画像は粗いが処理早い。.linear=画像綺麗だが処理遅い
        
        
        //---------------------------------------------ここから追加５（２）
        // 必要な枚数を計算
        //地面をスクロールして表示させるのに必要な枚数を計算してneedNumberに入れる
        //「＋２」は地面を多めに並べて右端が切れないようにしている
        //あとここ、割り算してるってことしかわからない。何をどう割ってるの？
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールを作成
        //５秒間かけて、左方向に画像一枚分スクロールさせるアクション
        //duration=間隔
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション 「-」が外れた　→どういうことになるの？
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→元の位置→左にスクロール、を無限に繰り返すアクションSKActionクラスのrepeatForever(:_)メソッド
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        //groundのスプライトを配置
        //必要な枚数分をfor文で繰り返して、「テクスチャ作成　→スプライト作成　→アクション設定　→scrollNodeに追加」を実施
        for i in 0..<needNumber {
            
            //-----------------------------------------------ここまで追加５（２）
            
            //テクスチャを指定してスプライトを作成する　スプライト＝画像を表示させるためのもの。ディスプレイってことにしよう
            //①テクスチャを指定してSKSPriteNodeクラス作成　②positionプロパティで表示位置指定　③addChild(_:)メソッドでスプライトを画面に表示
            let sprite = SKSpriteNode(texture: groundTexture)
            //↑追加５（３）　letをgroundSpriteからspriteに修正
            //スプライトの表示する位置(CGPoint)を決定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            //スプライトにアニメーションを設定
            sprite.run(repeatScrollGround)
            //↑追加５（３）　letをgroundSpriteからspriteに修正
            
            
            //-----------------ここから追加８　スプライトに物理体を設定する
            //これがなかったら、携帯画面外に永遠に落ちるってことか　大事だわ
            //SKPhysicsBody(rectangleOf:)=長方形物理体を付与する →？地面が四角形だから？
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            //追加１０　地面の衝突のカテゴリIDを設定　衝突判定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            
            //var isDynamic＝物理体が物理シミュレーションに動かされたかどうかを示す　→？
            //isDynamicプロパティ＝物理体が、他の物体による重力、摩擦、衝突に影響を受けるかどうかをコントロールする
            sprite.physicsBody?.isDynamic = false   //衝突時に動かないように設定
            //-----------------ここまで追加８　→次壁にも物理体設定する
            
            
            //シーンにスプライトを追加する
            scrollNode.addChild(sprite)
            //↑追加４addChild(groundSprite)からscrollNode.addChild(groundSprite)へ修正
            //↑追加５（３）　letをgroundSpriteからspriteに修正
            
            //--------------------------ここまで追加４
        }
    }
    
    //ここから追加６
    func setupCloud() {
        //雲の画像読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールを作成
        //５秒間かけて、左方向に画像一枚分スクロールさせるアクション
        //duration=間隔
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→元の位置→左にスクロール、を無限に繰り返すアクションSKActionクラスのrepeatForever(:_)メソッド
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        //cloudのスプライトを配置
        //必要な枚数分をfor文で繰り返して、「テクスチャ作成　→スプライト作成　→アクション設定　→scrollNodeに追加」を実施
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようになる
            
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            //スプライトにアニメーションを設定
            sprite.run(repeatScrollCloud)
            //スプライトを追加
            scrollNode.addChild(sprite)
        }
    }
    //ここまで追加６　雲をスクロール
    
    //ここから追加７　壁の設定
    func setupWall() {
        
        //壁のテクスチャ設定
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        //※ .nearest=画像は粗いが処理早い。.linear=画像綺麗だが処理遅い
        //壁は鳥との当たり判定があり、この「当たり判定」を行うスプライトに貼り付けるテクスチャについては画像優先にした方がいい
        
        //移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        //画面外まで移動するアクションを作成
        //画面の左を過ぎてさらに外側に移動するようにするものか！
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //元の位置に戻すのではなく、自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //上の2つのアクションを順に実行するアクション
        //画面の「-movingDistance」の位置までいったら消えてねってことね
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間のサイズを鳥のサイズの４倍とする slit=間隙
        let slit_length = birdSize.height * 4
        
        //隙間位置の上下の振れ幅を60ptとする　→200とか試したら振れ幅すごかったしWallの断端が見えたから、60がちょうどいいってことか
        let random_y_range: CGFloat = 60
        
        //空の中央位置（y座標）を取得 →図示すればその通りだわ
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //空の中央位置（sky_center_y）を基準にして下側の壁の中央位置を取得　→どういうこと？
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁をまとめるノードを作成
            let wall = SKNode()
            //↓最初ここから流してねってことかな？
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 //雲より手前、地面より奥　→エクセルの最前面とかの話だわ
            
            //下側の壁の中央位置にランダム値を足して、下側に壁の表示位置を決定する
            //let random_y_range: CGFloat = 60だよ
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //↓追加８　下の壁に物理体を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory // ←追加１０　衝突判定
            under.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            //上側の壁を作成 ノードに追加
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            wall.addChild(upper)
            
            //↓追加８　上の壁に物理体を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory // ←追加１０　衝突判定ID
            upper.physicsBody?.isDynamic = false
            
            //ここから追加１０　衝突判定ID
            //スコアカウント用の透明な壁を生成
            let scoreNode = SKNode()
            //全部できた後スコアの加点が変だった 加点される時もあるしされない時もあるって感じ　これ↓がないのが原因だったけど、なんで？
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            
            //透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            
            //壁をまとめているノードに透明な壁を追加
            wall.addChild(scoreNode)
            //ここまで追加１０
            
            
            //壁をまとめるノードにアニメーションを追加
            wall.run(wallAnimation)
            
            //壁を表示するノードに、今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
    
        //次の壁作成までの時間待ちアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //「壁を作成　→時間待ち　→壁を作成」を無限に繰り返すアクションを生成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        //repeatForeverAnimationを壁を表示するノードに追加して、、壁の作成を無限に繰り返すアクションを設定
        //以上のことを表示してくれいってこと
        wallNode.run(repeatForeverAnimation)
    }
    //ここまで追加７　壁の設定
    
    //ここから追加(課題５？）アイテム（ハート）を表示させる
    func setupHeart() {

        //var heart:SKSpriteNode!にしてるよ
        //Heart画像実装。当たり判定があるから画質重視（func setupWall()のとこで言ってた）。
        let heartTexture = SKTexture(imageNamed: "heart_allx")
        heartTexture.filteringMode = .linear
//        heart = SKSpriteNode(texture: heartTexture)//あとで
//        heart.size = CGSize(width: heart.size.width * 0.3, height: heart.size.height * 0.3)

        //ランダムなライミングでハートが出てきた方がタイミングが読みずらいので面白いかと思った
        let random_time:Int = Int.random(in: 2...6)
        
        let moveHeartDistance = self.frame.size.width + heartTexture.size().width
        let moveHeart = SKAction.moveBy(x: -moveHeartDistance, y: 0, duration: TimeInterval(random_time)) //wallは４
        let removeHeart = SKAction.removeFromParent()
        let heartAnimation = SKAction.sequence([moveHeart, removeHeart])

        //空の中央位置（y座標）を取得 setupWall()のそのまま
        //sky_center_yから上下左右ランダムに表示させればいいのではと思った
        let randomHeart_y_range: CGFloat = 100
        let randomHeart_x_range: CGFloat = 100

        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let randomHeart_y = CGFloat.random(in: -randomHeart_y_range...randomHeart_y_range)
        let randomHeart_x = CGFloat.random(in: -randomHeart_x_range...randomHeart_x_range)
        let heart_y = sky_center_y + randomHeart_y
        let heart_x = sky_center_y + randomHeart_x
        
        let createHeartAnimation = SKAction.run({
            //ハート作成
            let hearts = SKNode()
            hearts.position = CGPoint(x: heart_x, y: heart_y)
            hearts.zPosition = -50 //雲より手前、地面より奥　→壁と同じ面がいいと思う(-50)
            
            let heart = SKSpriteNode(texture: heartTexture)//あとで
            heart.size = CGSize(width: heart.size.width * 0.2, height: heart.size.height * 0.2)
                 
            //ハートに物理体設定
            heart.physicsBody = SKPhysicsBody(circleOfRadius: heart.size.height / 2)
            //↑heart.physicsBody = SKPhysicsBody(rectangleOf: heartTexture.size())だったけど、ハート取得時に鳥がハートのかなり手前で衝突判定してたからなんとかしようとした結果、birdの物理体設定と同じにすればいいと思って試した
            
            
            heart.physicsBody?.categoryBitMask = self.heartScoreCategory // 　衝突判定
            heart.physicsBody?.isDynamic = false
            

            hearts.addChild(heart)
            
            hearts.run(heartAnimation)

            self.heartNode.addChild(hearts)
        })

        //追加(課題２)次のheart作成までの時間待ちアクションを作成  →setupWall()の最後と一緒　無限にハートを作ってくれいってこと
        //後ろから追加する方が楽かも　→これをするために必要なものは…って考えるのがいいな　→次は
        let waitHeartAnimation = SKAction.wait(forDuration: 6)  //wallは２
        let repeatForeverHeartAnimation = SKAction.repeatForever(SKAction.sequence([createHeartAnimation, waitHeartAnimation]))
        heartNode.run(repeatForeverHeartAnimation)
    }
    //89行目へ
    //ここまで追加(課題５？）アイテム（ハート）を表示させる
    
    //ここから追加８　鳥の設定
    
    func setupBird() {
        //鳥の画像を２枚貼り付ける
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //２枚のテクスチャを交互に変更するアニメーションを作成
        //0.2秒ごとに交互の画像を描出させるのを、永遠にやってねてこと
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        //画面の横幅のほぼ左端かつ、画面の縦の７割くらいの位置にいてねってこと。１辺１のxy平面としたら（x,y）=（0.2,0.7）にいてってこと
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //↓追加８　物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //ここから追加１０　鳥の衝突判定
        //collisionBitMaskで、当たった時に跳ね返る相手を設定→ここでは、birdは地面と壁に当たった時に跳ね返るってことを設定してる collide=衝突する
        //contactTestBitMaskで、衝突判定を持つ相手を設定。壁と地面に当たった時にゲームオーバーに、スコアカウント用の透明な壁に当たった時はスコアアップするので、全部に衝突判定を設定する。
        //「|」はビットOR　→２進数の中でどっちかに「１」があれば１ってこと
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | heartScoreCategory
        
        //衝突した時に回転させない　→trueにしたら回転したわ
        bird.physicsBody?.allowsRotation = false
        
        //ここまで追加１０　鳥の衝突判定
        
        //アニメーションを作成とスプライトの追加
        bird.run(flap)
        addChild(bird)
        
    }
    //ここまで追加８　鳥の設定
    
    
    
    
    //ここから追加１１　衝突した時に起こることの設定
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        //ーーーーー「＆」→２進数の値の桁で、どっちにも「１」があったときに１ってこと。片方でも０なら０
        //--------逆に「｜」→どっちかに「１」があれば１。両方「０」の時のみ０を表示するよってこと
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコアカウント用の透明な壁と衝突した時、
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)" //追加１４（３）
            
            //-----------------ここから追加１４　ベストスコア更新か確認する
            //integer(forKey:)メソッドでキーを指定して値を取得
            //更新されていれば、set(_:forKey)メソッドで値とキーを指定して保存
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)" //追加１４（３）
                userDefaults.set(bestScore, forKey: "BEST")
            }
            //-----------------ここまで追加１４　ベストスコア更新か確認する
            
        //-------------ここから追加（課題６？）
        } else if (contact.bodyA.categoryBitMask & heartScoreCategory) == heartScoreCategory || (contact.bodyB.categoryBitMask & heartScoreCategory) == heartScoreCategory {
            
            print("itemScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"

            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"
            
            //ハートを除去する的なコードを書く
            heartNode.removeFromParent()
            
            //ここで音を出したい"powerup02"　→import AVFoundation
            playEffectSound()
           
            heartNode = SKNode()
            addChild(heartNode)
            setupHeart()
            
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
            }
           //---------------ここまで追加(課題６？)
           
            
        } else {
            //壁か地面と衝突した時、（多分、それ以外の場所と衝突した時ってこと）
            print("GameOver")
            scrollNode.speed = 0 //スクロールを停止する
            //衝突後は地面と反発するのみとする（リスタートするまで反発させない）←いるのこれ？
            bird.physicsBody?.collisionBitMask = groundCategory
            //なんで400.0？　　鳥が衝突した時の高さをもとに、鳥が地面に落ちる目での秒数（概算）＋１を計算
            let duration = bird.position.y / 400.0 + 1
            //指定秒数後、鳥をくるくる回転させる（1秒に１回回転させる）
            let roll = SKAction.rotate(byAngle: 2.0 * Double.pi * duration, duration: duration)
            
//            //追加(課題)ゲームオーバーの時ハートを除去する
//            heartNode.removeAllChildren()　→この位置だと衝突した瞬間にハートが消えるから違和感ある　→restart()に移動
            
            //ノードによって実行されるアクション(bird)のリストにアクション(roll)を追加して、引数ブロック（回転止める）をアクション（roll）の完了時に実行するように予定するってこと
            bird.run(roll, completion: {
                //回転が終わったら鳥の動きを止める
                self.bird.speed = 0
            })
        }
    }
    //ここまで追加１１　衝突した時に起こることの設定
    
    
    //ここから追加１２　画面をタップしたらリスタート。restart()メソッド実装
    //こういう状態でリスタートするよってことだな
    //スコア戻す。鳥を初期位置に戻す。壁を全て取り除く。スクロールと鳥のスピードを１に戻す。
    func restart() {
        //スコアを０に
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        
        //鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        //全ての壁を取り除く  childrenってNodeに貼られたやつらってこと？そういうことにしよう
        wallNode.removeAllChildren()
        
        //鳥とスクロールの動きを再開させる
        bird.speed = 1
        scrollNode.speed = 1
        
        //追加(課題)ゲームオーバーの時ハートもリセットする
        heartNode.removeAllChildren()
    }
    //ここまで追加１２　画面をタップしたらこの条件でリスタート
    
    
    //ここから追加１４（２）　スコアラベルを表示
    func setupScoreLabel() {
        //スコアラベルを作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 //一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        
        //追加(課題６？)　アイテムスコアラベルを作成 上のスコアと同じく作った
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        //ベストスコアラベルを作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)//(y: ...-90)だったのをアイテムスコア入れるために下げた
        bestScoreLabelNode.zPosition = 100 //一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "BestScore:\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    //ここまで追加１４（２）　スコアラベル表示
    
    
}
