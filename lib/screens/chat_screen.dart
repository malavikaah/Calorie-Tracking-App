import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/chat_message.dart';
import '../models/user_account.dart';
import '../services/pdf_export_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherEmail;

  const ChatScreen({Key? key, required this.otherEmail}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isOpeningReport = false;

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      Provider.of<AppState>(context, listen: false).sendMessage(
        widget.otherEmail,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: appState.getNameByEmail(widget.otherEmail),
          builder: (context, snapshot) {
            final name = snapshot.data ?? widget.otherEmail.split('@')[0];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Active Now', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
              ],
            );
          }
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: appState.getChatMessagesStream(widget.otherEmail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderEmail == appState.userAccount?.email;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? primaryColor 
                              : (Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF1E293B) 
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (msg.message.contains('[HEALTH REPORT]')) ...[
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: isMe ? Colors.white24 : Colors.teal.shade50,
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: Column(
                                   children: [
                                     Row(
                                       children: [
                                         const Icon(Icons.description_rounded, color: Colors.teal),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: Text(
                                             'Nutritional Health Report',
                                             style: TextStyle(
                                               fontWeight: FontWeight.bold,
                                               color: isMe ? Colors.white : Colors.teal.shade900,
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                     const SizedBox(height: 8),
                                     ElevatedButton(
                                         onPressed: _isOpeningReport ? null : () async {
                                           setState(() => _isOpeningReport = true);
                                           try {
                                             // If I am the patient and I sent this, show my own report
                                             // Otherwise, show the other person's report (dietitian viewing patient)
                                             if (appState.hasProfile && isMe) {
                                               await PdfExportService.generateAndPrintReport(
                                                 appState.userProfile, 
                                                 appState.nutriInsightsSummary
                                               );
                                             } else {
                                               await appState.viewPatientReport(widget.otherEmail);
                                             }
                                           } finally {
                                             if (mounted) setState(() => _isOpeningReport = false);
                                           }
                                         },
                                       style: ElevatedButton.styleFrom(
                                         backgroundColor: Colors.teal,
                                         foregroundColor: Colors.white,
                                         minimumSize: const Size(double.infinity, 36),
                                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                       ),
                                       child: _isOpeningReport 
                                         ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                         : const Text('VIEW REPORT', style: TextStyle(fontSize: 12)),
                                     ),
                                   ],
                                 ),
                               ),
                            ] else
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: isMe 
                                      ? Colors.white 
                                      : (Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white 
                                          : Colors.black87),
                                  fontSize: 15,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: isMe 
                                    ? Colors.white70 
                                    : (Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white60 
                                        : Colors.black45),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (appState.userAccount?.role == UserRole.user) ...[
            _buildSuggestionsRow(context),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF0F172A) 
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black38,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E293B) 
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 24,
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(BuildContext context) {
    final suggestions = [
      "👋 Hi! I'd like to get started with a consultation.",
      "📊 Can you review my shared health report?",
      "🍎 What are some healthy food swaps for my diet?",
      "💪 How can I naturally boost my protein intake?",
      "🥗 Can you suggest a balanced meal plan for my goals?",
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final text = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                Provider.of<AppState>(context, listen: false).sendMessage(
                  widget.otherEmail,
                  text,
                );
                _scrollToBottom();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
