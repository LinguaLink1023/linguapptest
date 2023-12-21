import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linguapp/services/auth/auth_service.dart';
import 'package:linguapp/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNote? _note;
  late final NoteService _noteService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _noteService = NoteService();
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
      note: note,
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

  Future<DatabaseNote> createNewNote() async {
    try {
      final existingNote = _note;
      if (existingNote != null) {
        print('Returning existing note: $existingNote'); // 添加日志
        return existingNote;
      }

      final currentUser = AuthService.firebase().currentUser!;
      final email = currentUser.email!;
      print('Current user email: $email'); // 添加日志

      final owner = await _noteService.getUser(email: email);
      print('Note owner: $owner'); // 添加日志

      final newNote = await _noteService.createNote(owner: owner);
      print('Created new note: $newNote'); // 添加日志

      return newNote;
    } catch (e) {
      print('An error occurred in createNewNote: $e');
      rethrow; // 重新抛出异常以便外部也能捕获
    }
  }

  void _deleteNoteIsTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _noteService.deleteNote(id: note.id);
    }
  }

  void _saveNoteIsTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _noteService.updateNote(
        note: note,
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
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasData && snapshot.data != null) {
                _note = snapshot.data as DatabaseNote;
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
