import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatResponse {
  final String response;
  final String chatId;
  final DateTime timestamp;

  ChatResponse({
    required this.response,
    required this.chatId,
    required this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'],
      chatId: json['chat_id'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatService {
  // Your deployed backend URL
  final String baseUrl = 'https://proton-chat-033d9cf9b2f8.herokuapp.com';
  
  // Local storage key
  static const String _chatIdKey = 'current_chat_id';

  // Send a message to the backend
  Future<ChatResponse> sendMessage({
    required String message,
    String? chatId,
    required String language,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'message': message,
          'chat_id': chatId,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        // Use utf8.decode to properly handle Tamil characters
        return ChatResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to send message: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get chat history from the backend
  Future<List<ChatMessage>> getChatHistory(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$chatId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Use utf8.decode to properly handle Tamil characters
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> messages = data['messages'];
        
        return messages.map((msg) => ChatMessage(
          text: msg['content'],
          isUser: msg['role'] == 'user',
          timestamp: DateTime.parse(msg['timestamp']),
        )).toList();
      } else {
        throw Exception('Failed to get chat history: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all chat histories (for history list)
  Future<List<Map<String, dynamic>>> getAllChatHistories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/list'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        // Use utf8.decode to properly handle Tamil characters
        final List<dynamic> histories = jsonDecode(utf8.decode(response.bodyBytes));
        return histories.map((h) => h as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to get chat histories: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Set language preference
  Future<void> setLanguagePreference(String language) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/language/set'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'language': language == 'ta' ? 'tamil' : 'english',
        }),
      );
    } catch (e) {
      debugPrint('Error setting language: $e');
      // Non-critical error, can be ignored
    }
  }

  // Save chat ID to local storage
  Future<void> saveChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatIdKey, chatId);
  }

  // Get saved chat ID from local storage
  Future<String?> getSavedChatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatIdKey);
  }

  // Clear current chat ID (for starting new chat)
  Future<void> clearCurrentChatId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatIdKey);
  }
}