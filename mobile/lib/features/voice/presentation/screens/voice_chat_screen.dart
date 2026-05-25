import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final List<_ChatBubble> _messages = [];
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _sessionId;
  String _language = 'hindi';

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatBubble(
      text: AppStrings.greetingHi,
      isUser: false,
      isGreeting: true,
    ));
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: 'voice_temp.wav',
      );
    }
  }

  Future<void> _stopAndSend() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    final path = await _recorder.stop();
    if (path == null) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(path, filename: 'voice.wav'),
        'language': _language,
        if (_sessionId != null) 'session_id': _sessionId,
        'include_greeting': _sessionId == null,
      });

      final response = await dio.post(
        ApiConstants.voiceChat,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      _sessionId = data['session_id'];

      setState(() {
        _messages.add(_ChatBubble(text: data['transcript'], isUser: true));
        _messages.add(_ChatBubble(text: data['ai_response'], isUser: false));
      });

      final audioUrl = data['audio_url'] as String?;
      if (audioUrl != null && audioUrl.startsWith('data:audio')) {
        final base64Data = audioUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        await _player.setAudioSource(AudioSource.uri(
          Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
        ));
        await _player.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _interruptPlayback() {
    _player.stop();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Guru'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (v) => setState(() => _language = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'hindi', child: Text('हिंदी')),
              const PopupMenuItem(value: 'english', child: Text('English')),
              const PopupMenuItem(value: 'hinglish', child: Text('Hinglish')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('गुरुजी सोच रहे हैं...'),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_player.playing)
                  IconButton(
                    onPressed: _interruptPlayback,
                    icon: const Icon(Icons.stop_circle, color: AppColors.error),
                  ),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopAndSend(),
                  onTap: _isRecording ? _stopAndSend : _startRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isRecording ? 90 : 72,
                    height: _isRecording ? 90 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: _isRecording ? 0.6 : 0.3),
                          blurRadius: _isRecording ? 30 : 15,
                          spreadRadius: _isRecording ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: 36,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Hold to speak • Tap to toggle',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final bool isGreeting;
  _ChatBubble({required this.text, required this.isUser, this.isGreeting = false});
}

class _MessageBubble extends StatelessWidget {
  final _ChatBubble message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.gold.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: message.isGreeting
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: message.isGreeting ? 'Noto Sans Devanagari' : null,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
