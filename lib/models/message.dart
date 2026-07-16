class Message {
  final int? id;
  final String role;
  final String content;
  final bool isStreaming;

  const Message({
    this.id,
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: json['role'],
      content: json['content'],
    );
  }
}