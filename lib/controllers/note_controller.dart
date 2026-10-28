import 'package:get/get.dart';
import 'package:momento/controllers/auth_controller.dart';
import 'package:momento/models/note_model.dart';
import 'package:momento/services/api_service.dart';
import 'package:momento/services/note_service.dart';

class NoteController extends GetxController {
  late final NoteService _noteService;

  final notes = <NoteModel>[].obs;
  final isLoading = false.obs;

  NoteModel? get myNote {
    final currentUserId =
        Get.find<AuthController>().currentUser.value?.id ?? '';
    try {
      return notes.firstWhere((n) => n.isMine || n.userId == currentUserId);
    } catch (_) {
      return null;
    }
  }

  List<NoteModel> get friendsNotes {
    final currentUserId =
        Get.find<AuthController>().currentUser.value?.id ?? '';
    return notes.where((n) => !n.isMine && n.userId != currentUserId).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _noteService = Get.isRegistered<NoteService>()
        ? Get.find<NoteService>()
        : NoteService(Get.find<ApiService>());
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      isLoading.value = true;
      final currentUserId =
          Get.find<AuthController>().currentUser.value?.id ?? '';
      final fetched = await _noteService.getNotes(currentUserId: currentUserId);
      notes.assignAll(fetched);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createNote(
    String text, {
    Map<String, dynamic>? musicTrack,
  }) async {
    try {
      isLoading.value = true;
      final newNote = await _noteService.createNote(
        text,
        musicTrack: musicTrack,
      );
      if (newNote != null) {
        await loadNotes();
        return true;
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      final success = await _noteService.deleteNote(noteId);
      if (success) {
        notes.removeWhere((n) => n.id == noteId);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
