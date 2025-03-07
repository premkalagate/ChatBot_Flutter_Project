import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser botUser = ChatUser(id: "1", firstName: "Bot");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 55, 175, 119),
        centerTitle: true,
        title: const Text('ChatBot', style: TextStyle(color: Colors.white)),
      ),
      body: _buildUI(),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copied to clipboard")),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      typingUsers: typingUsers,
      messageOptions: MessageOptions(
        showOtherUsersAvatar: false, 
        onLongPressMessage: (message) {
          _copyToClipboard(context, message.text);
        },
        currentUserContainerColor: Color.fromARGB(255, 55, 175, 119), //User container color
        containerColor: Color.fromARGB(255, 104, 104, 104), // Bot response color
        textColor: Colors.white,
      ),
      inputOptions: InputOptions(
        inputDecoration: InputDecoration(
          filled: true,
          fillColor: const Color.fromARGB(255, 104, 104, 104), // Background color of input box
          hintText: "Type your message...",
          hintStyle: TextStyle(
              color:
                  const Color.fromARGB(255, 255, 255, 255)), // Hint text color
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), // Rounded corners
            borderSide: BorderSide.none, // Remove default border
          ),
        ),
        inputTextStyle: TextStyle(
          color: Colors.white, // Set typed text color to white
          fontSize: 16,
        ),
        sendButtonBuilder: (send) => IconButton(
          icon: Icon(Icons.send,
              color: Color.fromARGB(255, 55, 175, 119)), // Custom send button
          onPressed: send,
        ), // Input field background
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages.insert(0, chatMessage);
    });

    try {
      String question = chatMessage.text;
      setState(() {
        typingUsers.add(botUser);
      });
      gemini.streamGenerateContent(question).listen((event) {
        // Extract response only from `TextPart`
        String response = event.content?.parts
                ?.whereType<TextPart>() // Ensure we get only TextPart
                .map((part) => part.text) // Extract text from each part
                .join(" ") ??
            "No response from Bot."; // Join responses

        setState(() {
          typingUsers.remove(botUser);
          if (messages.isNotEmpty && messages.first.user == botUser) {
            // If last message is from the bot, update it
            messages[0] = ChatMessage(
              user: botUser,
              createdAt: messages[0].createdAt,
              text: "${messages[0].text} $response", // Append response
            );
          } else {
            // Otherwise, add a new bot message
            messages.insert(
              0,
              ChatMessage(
                user: botUser,
                createdAt: DateTime.now(),
                text: response,
              ),
            );
          }
        });
      });
    } catch (e) {
      print("Error: $e");
    }
  }
}
