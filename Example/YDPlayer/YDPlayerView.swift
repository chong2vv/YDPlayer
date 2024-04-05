//
//  YDPlayerView.swift
//  YDPlayer_Example
//
//  Created by 王远东 on 2023/10/31.
//  Copyright © 2023 wangyuandong. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import YDPlayer
import SnapKit
import Kingfisher
import YDUtilKit

@objcMembers
open class YDPlayerView: UIView {
    
    public var playAfterLoaded: Bool = true
    
    public var playerStatus: ((_ status: AVPlayer.Status) -> Void)? = nil
    
    public var playbackStatus: ((_ status: PlaybackStatus) -> Void)? = nil
    
    public var loadedBlock: ((_ time: TimeInterval, _ duration: TimeInterval) -> Void)? = nil
    
    public var progressBlock: ((_ time: TimeInterval, _ duration: TimeInterval) -> Void)? = nil
    
    public var finishBlock: (() -> Void)? = nil
    
    public var bitRate: Float = 0
    
    public var audioCategory: AVAudioSession.Category = AVAudioSessionCategoryPlayback as AVAudioSession.Category

    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            if let player = player {
                player.videoGravity = videoGravity
            }
            //
            switch videoGravity {
            case .resize:
                imageView.contentMode = .scaleToFill
                break
            case .resizeAspect:
                imageView.contentMode = .scaleAspectFit
                break
            case .resizeAspectFill:
                imageView.contentMode = .scaleAspectFill
                break
            default:
                break
            }
        }
    }
    
    public var playbackTimeInterval: TimeInterval = 1 {
        didSet {
            if let player = player {
                player.playbackTimeInterval = playbackTimeInterval
            }
        }
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: self.bounds)
        switch videoGravity {
        case .resize:
            view.contentMode = .scaleToFill
        case .resizeAspect:
            view.contentMode = .scaleAspectFit
        case .resizeAspectFill:
            view.contentMode = .scaleAspectFill
        default:
            break
        }
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var playerView: UIView = {
        let view = UIView(frame: self.bounds)
        view.clipsToBounds = true
        return view
    }()
    
    public var showsLoadingView: Bool = false
    
    lazy var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        view.hidesWhenStopped = true
        view.color = .gray
        return view
    }()
    
    private var player: PlayerWarpper? = nil
    
    public var isPlaying: Bool {
        if let player = player {
            return player.isPlaying
        }
        return false
    }
    
    public var isPaused: Bool {
        if let player = player {
            return player.isPaused
        }
        return false
    }
    
    public var needsResume: Bool = false
    
    public var isPlayerEmpty: Bool {
        return player == nil
    }
    
    public var rate: Float = 1.0 {
        didSet {
            player?.rate = rate
        }
    }
    
    public var isMuted: Bool = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    
    var willEnterForegroundObserver: Any? = nil
    var didBecomeActiveObserver: Any? = nil
    
    var willResignActiveObserver: Any? = nil
    var didEnterBackgroundObserver: Any? = nil
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        if let observer = willEnterForegroundObserver {
            NotificationCenter.default.removeObserver(observer)
            willEnterForegroundObserver = nil
        }
        if let observer = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            didBecomeActiveObserver = nil
        }
        if let observer = willResignActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            willResignActiveObserver = nil
        }
        if let observer = didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(observer)
            didEnterBackgroundObserver = nil
        }
    }
}

extension YDPlayerView {
    
    func setupView() {
        //
        self.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        
        self.addSubview(playerView)
        playerView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        
        //
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
        })
        //
        willResignActiveObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else { return }
            self.setNeedsResume("willResignActiveNotification")
        }
        didEnterBackgroundObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else { return }
            self.setNeedsResume("didEnterBackgroundNotification")
        }
        willEnterForegroundObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else { return }
            self.resumeIfNeeded("willEnterForegroundNotification")
        }
        didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self] (_) in
            guard let self = self else { return }
            self.resumeIfNeeded("didBecomeActiveNotification")
        }
    }
    
    public func setImageURL(_ fileOrUrl: String?, placeholder: UIImage? = nil) {
        if let file = fileOrUrl {
            if file.hasPrefix("http://") || file.hasPrefix("https://") {
                if let url = URL(string: file) {
                    imageView.kf.setImage(with: url, placeholder: placeholder, options: [.transition(.fade(0.2))])
                }
            } else {
                imageView.image = UIImage(contentsOfFile: file)
            }
        } else {
            imageView.image = nil
        }
    }
    
    public func setVideoURL(_ fileOrUrl: String?, hasPreview: Bool = true) {
        do {
            try AVAudioSession.sharedInstance().setCategory(audioCategory as String)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        //
        if let str = fileOrUrl {
            var url: URL? = nil
            if str.hasPrefix("http://") || str.hasPrefix("https://") {
                url = URL(string: str)
            } else if FileManager.default.fileExists(atPath: str) {
                url = URL(fileURLWithPath: str)
            }
            //
            if let url = url {
                let asset = AVURLAsset(url: url)
                if hasPreview {
                    imageView.image = asset.copyImage(atTime: 0)
                }
                //
                DispatchQueue.global().async {
                    var rate: Float = 0
                    for track in asset.tracks {
                        rate += track.estimatedDataRate
                    }
                    DispatchQueue.main.async {
                        self.bitRate = rate
                    }
                }
                //
                player?.stop()
                player = PlayerWarpper(with: url)
                player?.videoGravity = videoGravity
                player?.playbackTimeInterval = playbackTimeInterval
                player?.isMuted = isMuted
                player?.rate = rate
                //
                player?.playerStatus = { [weak self] (status, error) in
                    guard let self = self else { return }
                    if status == .readyToPlay {
                        if self.playAfterLoaded {
                            self.play()
                        }
                    }
                    if let error = error {
                        print("Player error: \(error as NSError) \nurl: \(url)")
                    }
                    if let closure = self.playerStatus {
                        closure(status)
                    }
                }
                //
                player?.playbackStatus = { [weak self] (status) in
                    guard let self = self else { return }
                    switch status {
                    case .buffering:
                        if self.showsLoadingView, !url.isFileURL {
                            self.loadingView.startAnimating()
                        }
                        break
                    case .ended:
                        self.loadingView.stopAnimating()
                        if let finishBlock = self.finishBlock {
                            finishBlock()
                        }
                        break
                    default:
                        self.loadingView.stopAnimating()
                        break
                    }
                    if let closure = self.playbackStatus {
                        closure(status)
                    }
                }
                //
                player?.loadedTime = { [weak self] (time, duration) in
                    guard let self = self else { return }
                    if let loadedBlock = self.loadedBlock {
                        loadedBlock(time, duration)
                    }
                }
                //
                player?.playbackTime = { [weak self] (time, duration) in
                    guard let self = self else { return }
                    if let progressBlock = self.progressBlock {
                        progressBlock(time, duration)
                    }
                }
                //
                player?.attach(to: playerView)
            }
        }
    }
    
    public func replay() {
        do {
            try AVAudioSession.sharedInstance().setCategory(audioCategory as String)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        //
        playAfterLoaded = true
        player?.seek(time: 0, playAfter: playAfterLoaded)
    }
    
    public func play() {
        do {
            try AVAudioSession.sharedInstance().setCategory(audioCategory as String)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        playerView.frame = bounds // Fixed for iOS 10.x
        playAfterLoaded = true
        player?.play()
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func resume() {
        player?.resume()
    }
    
    public func stop() {
        player?.stop()
    }
    
    public func seek(time: TimeInterval, playAfter: Bool = true, replay: Bool = false) {
        if let player = player {
            if replay {
                player.seek(time: time, playAfter: playAfter)
            } else if !player.isEnded {
                player.seek(time: time, playAfter: playAfter)
            }
        }
    }
    
    private func setNeedsResume(_ sender: String = "???") {
        if isPlaying {
            print("VideoPlayerView.\(sender).setNeedsResume")
            needsResume = true
            pause()
        }
    }
    
    private func resumeIfNeeded(_ sender: String = "???") {
        if needsResume {
            print("VideoPlayerView.\(sender).resumeIfNeeded")
            needsResume = false
            resume()
        }
    }
}
