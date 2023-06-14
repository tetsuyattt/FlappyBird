//
//  ViewController.swift
//  FlappyBird
//
//  Created by 富樫　哲也 on 2023/06/14.
//

import UIKit
import SpriteKit  //追加１　この中でSpriteKitを使うための必須コード(わかる)


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //----------------------------ここから追加１　SKViewクラスのpresentScene()メソッドを使ってSKSceneを設定
        
        //SKViewに型を変換する　←？どういうこと？
        let skView = self.view as! SKView
        //FPSを表示する（わかる）　FPS→画面が１秒間に何回更新されてるかを示す。画面の右下に出る
        skView.showsFPS = true
        //ノードの数を表示する（わかる）　画面の右下に出る。ノードの数が多いと処理が重くなってFPS値が減っていく。
        //FPSが落ちると動きがカクカクしてイラつく　→FPSが落ちないようにゲームを作るのが大事
        skView.showsNodeCount = true
        //ビューと同じサイズでシーンを作成する（わかる）
        //--------↓追加３　let scene = SKScene(size:skView.frame.size)から修正　→GameSceneクラスに変更
        let scene = GameScene(size:skView.frame.size)
        
        
        //ビューにシーンを表示する　作成した「scene」をSKViewクラスの「presentScene()」メソッドで設定する
        skView.presentScene(scene)
        
        //----------------------------ここまで追加１
    }
    
    //---------------------------ここから追加７
    //ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    //---------------------------ここまで追加７

}

