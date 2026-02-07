import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/featherless_service.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceModeWidget extends StatefulWidget {
  const VoiceModeWidget({super.key});

  @override
  State<VoiceModeWidget> createState() => _VoiceModeWidgetState();
}

class _VoiceModeWidgetState extends State<VoiceModeWidget>
    with TickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  String _statusText = 'Say "Jarvis" to wake up';
  String _currentTranscription = '';
  String _currentResponse = '';
  WebSocketChannel? _voiceChannel;
  Timer? _statusTimer;
  FeatherlessService? _service;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _voiceWaveController;
  late Animation<double> _voiceWaveAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _connectVoiceService();
    _startStatusCheck();
    // Auto-start listening
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _state = VoiceState.listening;
          _statusText = "Listening for 'Jarvis'...";
        });
      }
    });
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Voice wave animation for when JARVIS speaks
    _voiceWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _voiceWaveAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _voiceWaveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Close WebSocket - this will trigger backend to stop listening
    _voiceChannel?.sink.close();
    _statusTimer?.cancel();
    _pulseController.dispose();
    _voiceWaveController.dispose();
    super.dispose();
  }

  void _connectVoiceService() async {
    // Voice service will use speech_to_text and flutter_tts directly
    // Integration with Featherless.ai will be done through ChatProvider
    setState(() {
      _state = VoiceState.idle;
      _statusText = 'Tap to speak';
    });
  }

  void _startStatusCheck() {
    // Status checking not needed for direct voice integration
  }

  void _handleUserSpeech(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _state = VoiceState.processing;
      _statusText = 'Processing...';
      _currentTranscription = text;
    });

    HapticFeedback.mediumImpact();
  }

  void _handleAssistantResponse(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _state = VoiceState.speaking;
      _statusText = 'Speaking...';
      _currentResponse = text;
    });

    // Return to listening after speaking (give time for TTS to finish)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _state = VoiceState.listening;
          _statusText = "Listening for 'Jarvis'...";
          _currentTranscription = '';
          _currentResponse = '';
        });
      }
    });
  }

  void _toggleListening() {
    // Voice mode is always active, so this just provides haptic feedback
    HapticFeedback.mediumImpact();

    // Don't allow toggling - always listening
    if (_state == VoiceState.idle || _state == VoiceState.error) {
      setState(() {
        _state = VoiceState.listening;
        _statusText = "Listening for 'Jarvis'...";
      });
    }
    // Always stay in listening mode - removed toggle off functionality
  }

  Color _getOrbColor(bool isDark) {
    switch (_state) {
      case VoiceState.idle:
        return isDark
            ? AppTheme.textTertiary
            : AppTheme.textDarkSecondary;
      case VoiceState.listening:
        return AppTheme.primaryMaroon;
      case VoiceState.processing:
        return AppTheme.warning;
      case VoiceState.speaking:
        return AppTheme.accentGreen;
      case VoiceState.error:
        return AppTheme.error;
    }
  }

  IconData _getOrbIcon() {
    switch (_state) {
      case VoiceState.idle:
        return CupertinoIcons.mic;
      case VoiceState.listening:
        return CupertinoIcons.mic_fill;
      case VoiceState.processing:
        return CupertinoIcons.waveform;
      case VoiceState.speaking:
        return CupertinoIcons.speaker_2_fill;
      case VoiceState.error:
        return CupertinoIcons.exclamationmark_triangle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradient : null,
        color: isDark ? null : AppTheme.bgLightSecondary,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main orb with voice waves - centered
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _voiceWaveAnimation]),
                  builder: (context, child) {
                    final shouldPulse = _state == VoiceState.listening ||
                        _state == VoiceState.processing;
                    final scale = shouldPulse ? _pulseAnimation.value : 1.0;
                    final isSpeaking = _state == VoiceState.speaking;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Voice wave rings (only when speaking)
                        if (isSpeaking) ...[
                          // Outer ring
                          Transform.scale(
                            scale: _voiceWaveAnimation.value,
                            child: Container(
                              width: 320,
                              height: 320,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getOrbColor(isDark).withOpacity(
                                    0.3 * (1 - (_voiceWaveAnimation.value - 1.0) / 0.3),
                                  ),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          // Middle ring
                          Transform.scale(
                            scale: 1.0 + (_voiceWaveAnimation.value - 1.0) * 0.6,
                            child: Container(
                              width: 290,
                              height: 290,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getOrbColor(isDark).withOpacity(
                                    0.4 * (1 - (_voiceWaveAnimation.value - 1.0) / 0.3 * 0.6),
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          // Inner ring
                          Transform.scale(
                            scale: 1.0 + (_voiceWaveAnimation.value - 1.0) * 0.3,
                            child: Container(
                              width: 270,
                              height: 270,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getOrbColor(isDark).withOpacity(
                                    0.5 * (1 - (_voiceWaveAnimation.value - 1.0) / 0.3 * 0.3),
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Main orb
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getOrbColor(isDark).withOpacity(0.15),
                              border: Border.all(
                                color: _getOrbColor(isDark).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _getOrbColor(isDark),
                                      _getOrbColor(isDark).withOpacity(0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getOrbColor(isDark).withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getOrbIcon(),
                                  size: 80,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Status text
              Text(
                _statusText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),

              const SizedBox(height: 16),

              // Current transcription
              if (_currentTranscription.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _currentTranscription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                ),

              // Current response
              if (_currentResponse.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.systemGrey6.darkColor
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _currentResponse,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Hint text
              Text(
                _state == VoiceState.idle
                    ? 'Tap the microphone to start'
                    : _state == VoiceState.listening
                        ? 'Speak naturally'
                        : '',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
