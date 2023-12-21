import 'package:flutter/material.dart';
import 'package:linguapp/services/auth/auth_service.dart';
import 'package:linguapp/utilities/generics/get_arguments.dart';
import 'package:linguapp/services/cloud/cloud_note.dart';
import 'package:linguapp/services/cloud/cloud_storage_exceptions.dart';
import 'package:linguapp/services/cloud/firebase_cloud_storage.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _noteService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _noteService = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _noteService.updateNote(
      documentId: note.documentId,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  // Future<DatabaseNote> createNewNote() async {
  //   final existingNote = _note;
  //   if (existingNote != null) {
  //     return existingNote;
  //   }

  //   final currentUser = AuthService.firebase().currentUser!;
  //   final email = currentUser.email!;
  //   final owner = await _noteService.getUser(email: email);
  //   return await _noteService.createNote(owner: owner);
  // }

  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    try {
      final widgetNote = context.getArgument<CloudNote>();
      if (widgetNote != null) {
        _note = widgetNote;
        _textController.text = widgetNote.text;
        return widgetNote;
      }

      final existingNote = _note;
      if (existingNote != null) {
        // print('Returning existing note: $existingNote'); // 添加日志
        return existingNote;
      }

      final currentUser = AuthService.firebase().currentUser!;
      final userId = currentUser.id;
      // print('Current user email: $email'); // 添加日志
      // print('Note owner: $owner'); // 添加日志

      final newNote = await _noteService.createNewNote(ownerUserId: userId);
      _note = newNote;
      // print('Created new note: $newNote'); // 添加日志
      return newNote;
    } catch (e) {
      // print('An error occurred in createNewNote: $e');
      rethrow; // 重新抛出异常以便外部也能捕获
    }
  }

  void _deleteNoteIsTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _noteService.deleteNote(documentId: note.documentId);
    }
  }

  void _saveNoteIsTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _noteService.updateNote(
        documentId: note.documentId,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteNoteIsTextIsEmpty();
    _saveNoteIsTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasData && snapshot.data != null) {
                _setupTextControllerListener();
                return TextField(
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Start typing your note...',
                  ),
                );
              } else {
                return const Text('Error: note data is null');
              }
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
