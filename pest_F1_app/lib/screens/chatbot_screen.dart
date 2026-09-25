import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends StatefulWidget {
  final Map<String, dynamic>? initialContext;

  const ChatbotScreen({super.key, this.initialContext});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Voice Input & Output states
  bool _isListening = false;
  int? _speakingIndex;

  final List<String> _suggestedPrompts = [
    "How to treat Rice Brown Plant Hopper?",
    "Best organic pesticides for leaf blights?",
    "Preventive measures for stem borer",
    "How to manage tomato early blight?",
  ];

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    String welcomeMsg =
        "👋 Hello! I am AgriScan AI, your agricultural chatbot assistant. How can I help you protect your crops today?";

    if (widget.initialContext != null) {
      final issue =
          widget.initialContext!['display_name'] ??
          widget.initialContext!['class'] ??
          'Detected Condition';
      welcomeMsg =
          "🌿 I see your recent scan detected **$issue**. Would you like recommended treatments, organic remedies, or prevention advice?";
    }

    _messages.add(ChatMessage(text: welcomeMsg, isUser: false));
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _speakingIndex = null;
      _isListening = false;
      _initWelcomeMessage();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✨ Chat reset cleanly! Starting fresh conversation."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleVoiceInput() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎙️ Listening... Speak your crop or pest question."),
          duration: Duration(seconds: 3),
        ),
      );
      // Simulate speech recognition result after brief pause
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isListening) {
          setState(() {
            _messageController.text =
                "How to treat brown plant hopper organically?";
            _isListening = false;
          });
        }
      });
    }
  }

  void _speakMessage(int index, String text) {
    setState(() {
      if (_speakingIndex == index) {
        _speakingIndex = null;
      } else {
        _speakingIndex = index;
      }
    });

    if (_speakingIndex == index) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("🔊 Reading AI response aloud..."),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: "Stop",
            textColor: Colors.amber,
            onPressed: () {
              setState(() => _speakingIndex = null);
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textOverride]) async {
    final query = textOverride ?? _messageController.text.trim();
    if (query.isEmpty || _isLoading) return;

    if (textOverride == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    // Build chat history for Gemini
    final history =
        _messages
            .map(
              (m) => {'role': m.isUser ? 'user' : 'model', 'content': m.text},
            )
            .toList();

    final result = await _geminiService.sendChatMessage(
      prompt: query,
      context: widget.initialContext,
      history: history,
    );

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: result['reply'] ?? 'Sorry, no response returned.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AgriScan AI Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Powered by Gemini AI",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: "Clear Chat / Start Fresh",
            onPressed: _clearChat,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (widget.initialContext != null) _buildScanContextBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, index);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryGreen,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "AgriScan AI is thinking...",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          _buildSuggestedChips(),
          _buildInputArea(primaryGreen),
        ],
      ),
    );
  }

  Widget _buildScanContextBanner() {
    final issue =
        widget.initialContext!['display_name'] ??
        widget.initialContext!['class'] ??
        'Scan Result';
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F5E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.eco, color: Color(0xFF2D6A4F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Context: $issue",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    final isUser = msg.isUser;
    final isSpeaking = _speakingIndex == index;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1B4332) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1B262C),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            if (!isUser) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _speakMessage(index, msg.text),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isSpeaking
                            ? const Color(0xFF40916C).withOpacity(0.2)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_mute_outlined,
                    size: 18,
                    color:
                        isSpeaking ? const Color(0xFF2D6A4F) : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children:
            _suggestedPrompts.map((prompt) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF40916C), width: 1),
                  label: Text(
                    prompt,
                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => _sendMessage(prompt),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildInputArea(Color primaryGreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Ask about crops, pests, treatments...",
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF0F4F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 6),
            // Mic / Voice Input Button
            CircleAvatar(
              backgroundColor:
                  _isListening ? Colors.red : primaryGreen.withOpacity(0.12),
              radius: 20,
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _isListening ? Colors.white : primaryGreen,
                  size: 20,
                ),
                tooltip: "Voice Input",
                onPressed: _toggleVoiceInput,
              ),
            ),
            const SizedBox(width: 6),
            // Send Button
            CircleAvatar(
              backgroundColor: primaryGreen,
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                tooltip: "Send Message",
                onPressed: () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
