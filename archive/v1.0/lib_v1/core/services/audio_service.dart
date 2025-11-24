import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// 音频服务 - 处理所有音效播放
///
/// 提供定时器完成、任务完成等音效
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  /// 初始化音频服务
  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// 播放专注完成音效
  Future<void> playFocusComplete() async {
    if (_isMuted) return;

    try {
      // 使用系统音效或自定义音效
      await _playSystemSound();
    } catch (e) {
      // 静默失败,不影响用户体验
      print('播放专注完成音效失败: $e');
    }
  }

  /// 播放休息完成音效
  Future<void> playBreakComplete() async {
    if (_isMuted) return;

    try {
      await _playSystemSound();
    } catch (e) {
      print('播放休息完成音效失败: $e');
    }
  }

  /// 播放任务完成音效
  Future<void> playTaskComplete() async {
    if (_isMuted) return;

    try {
      await _playSystemSound();
    } catch (e) {
      print('播放任务完成音效失败: $e');
    }
  }

  /// 播放提示音
  Future<void> playNotification() async {
    if (_isMuted) return;

    try {
      await _playSystemSound();
    } catch (e) {
      print('播放提示音失败: $e');
    }
  }

  /// 播放警告音
  Future<void> playWarning() async {
    if (_isMuted) return;

    try {
      await _playSystemSound();
    } catch (e) {
      print('播放警告音失败: $e');
    }
  }

  /// 播放系统音效
  Future<void> _playSystemSound() async {
    // 使用系统反馈音效
    await SystemSound.play(SystemSoundType.alert);
  }

  /// 设置静音
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// 获取静音状态
  bool get isMuted => _isMuted;

  /// 切换静音状态
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// 释放资源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
