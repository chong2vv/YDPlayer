//
//  PlayerWarpper.swift
//  YDPlayer
//
//  Created by 王远东 on 2023/10/31.
//  Copyright © 2023 wangyuandong. All rights reserved.
//

import Foundation
import CoreMedia

@objc
public enum PlaybackStatus: Int {
    case buffering = 0
    case playing
    case paused
    case ended
}

public class PlayerWarpper {
    
    public init(with url: URL) {
        player = YDPlayer(url: url)
        player?.panGestureRecognizer.isEnabled = false
    }
    
    private var player: YDPlayer? = nil
    
    public var playerStatus: ((_ status: AVPlayer.Status, _ error: Error?) -> Void)? = nil {
        didSet {
            guard let closure = playerStatus else {
                return
            }
            player?.playerStatus = { (status, error) in
                closure(status, error)
            }
        }
    }
    
    public var playbackStatus: ((_ status: PlaybackStatus) -> Void)? = nil {
        didSet {
            guard let closure = playbackStatus else {
                return
            }
            player?.playbackStatus = { (status) in
                switch status {
                case .buffering:
                    closure(.buffering)
                case .playing:
                    closure(.playing)
                case .paused:
                    closure(.paused)
                case .ended:
                    closure(.ended)
                default:
                    break
                }
            }
        }
    }
    
    public var playbackTime: ((_ time: TimeInterval, _ duration: TimeInterval) -> Void)? = nil {
        didSet {
            guard let closure = playbackTime else {
                return
            }
            player?.playbackTime = { (time, duration) in
                closure(time, duration)
            }
        }
    }
    
    public var loadedTime: ((_ time: TimeInterval, _ duration: TimeInterval) -> Void)? = nil {
        didSet {
            guard let closure = loadedTime else {
                return
            }
            player?.loadedTime = { (time, duration) in
                closure(time, duration)
            }
        }
    }
    
    public var playbackTimeInterval: TimeInterval = 1  {
        didSet {
            player?.playbackTimeInterval = playbackTimeInterval
        }
    }
    
    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            player?.videoGravity = videoGravity
        }
    }
    
    public var rate: Float {
        set {
            player?.rate = newValue
        }
        get {
            return player?.rate ?? 1.0
        }
    }
    
    public var isMuted: Bool {
        set {
            player?.isMuted = newValue
        }
        get {
            return player?.isMuted ?? false
        }
    }
    
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
    
    public var isEnded: Bool {
        if let player = player {
            return player.isEnded
        }
        return false
    }
    
    public func play() {
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
    
    public func seek(time: TimeInterval, playAfter: Bool) {
        if let player = player {
            player.seek(toTime: time, tolerance: kCMTimeZero) { [weak player](finished) in
                guard let player = player else { return }
                if playAfter {
                    player.play()
                }
            }
        }
    }
    
    public func attach(to view: UIView) {
        player?.attach(to: view)
    }
    
}

