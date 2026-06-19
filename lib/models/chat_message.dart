class ChatMessage {
  final String senderEmail;
  final String receiverEmail;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderEmail,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderEmail: json['senderEmail'],
      receiverEmail: json['receiverEmail'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
