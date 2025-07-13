// lib/core/services/command_service.dart
import 'package:flutter/foundation.dart';

/// Defines the signature for a command handler function.
/// It can optionally receive a map of arguments.
typedef CommandHandler = Future<void> Function(Map<String, dynamic>? args);

/// A central service for registering and executing commands throughout the application.
/// This decouples the UI from the business logic, allowing for a more flexible
/// and extensible architecture, particularly for the plugin system.
class CommandService {
  // Private constructor for singleton pattern.
  CommandService._privateConstructor();

  // The single instance of the service.
  static final CommandService _instance = CommandService._privateConstructor();

  /// Provides access to the singleton instance of the CommandService.
  static CommandService get instance => _instance;

  // A map to store the registered command handlers.
  final Map<String, CommandHandler> _handlers = {};

  /// Registers a command with its corresponding handler.
  /// If a command with the same ID is already registered, it will be overwritten.
  ///
  /// [commandId] The unique identifier for the command.
  /// [handler] The function to be executed when the command is called.
  void registerCommand(String commandId, CommandHandler handler) {
    debugPrint('Registering command: $commandId');
    _handlers[commandId] = handler;
  }
  
  /// Unregisters a command.
  ///
  /// [commandId] The unique identifier for the command to unregister.
  void unregisterCommand(String commandId) {
    if (_handlers.containsKey(commandId)) {
      debugPrint('Unregistering command: $commandId');
      _handlers.remove(commandId);
    }
  }

  /// Executes a registered command by its ID.
  ///
  /// [commandId] The ID of the command to execute.
  /// [args] An optional map of arguments to pass to the command handler.
  ///
  /// Throws an [Exception] if the command is not found.
  Future<void> executeCommand(
    String commandId, {
    Map<String, dynamic>? args,
  }) async {
    if (_handlers.containsKey(commandId)) {
      debugPrint('Executing command: $commandId with args: $args');
      try {
        await _handlers[commandId]!(args);
      } catch (e, stackTrace) {
        debugPrint('Error executing command "$commandId": $e');
        debugPrint(stackTrace.toString());
        // Rethrowing allows the caller to handle the error if needed.
        rethrow;
      }
    } else {
      debugPrint('Command not found: $commandId');
      throw Exception('Command "$commandId" not found.');
    }
  }

  /// Checks if a command is registered.
  bool hasCommand(String commandId) {
    return _handlers.containsKey(commandId);
  }
} 