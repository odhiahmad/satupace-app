import 'package:flutter/material.dart';
import '../../core/api/direct_match_api.dart';
import '../../core/services/secure_storage_service.dart';

class DirectMatchProvider with ChangeNotifier {
  final DirectMatchApi _api;
  final SecureStorageService _storage;

  // Candidates (algorithmically suggested runners)
  List<Map<String, dynamic>> _candidates = [];
  bool _loadingCandidates = false;
  String? _candidatesError;

  // My Matches — split by status
  List<Map<String, dynamic>> _pendingMatches = [];
  List<Map<String, dynamic>> _acceptedMatches = [];
  bool _loadingMatches = false;
  String? _matchesError;

  String? _myUserId;

  DirectMatchProvider({
    required DirectMatchApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get candidates => _candidates;
  List<Map<String, dynamic>> get pendingMatches => _pendingMatches;
  List<Map<String, dynamic>> get acceptedMatches => _acceptedMatches;

  bool get loadingCandidates => _loadingCandidates;
  bool get loadingMatches => _loadingMatches;

  String? get candidatesError => _candidatesError;
  String? get matchesError => _matchesError;

  // Backward-compat aliases
  bool get loading => _loadingMatches;
  String? get error => _matchesError;
  List<Map<String, dynamic>> get matches => _acceptedMatches;

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<String?> _getMyUserId() async {
    _myUserId ??= await _storage.readUserId();
    return _myUserId;
  }

  void _enrichWithPartner(Map<String, dynamic> match, String? myId) {
    final u1Id = (match['user_1_id'] ?? '').toString();
    final u2Id = (match['user_2_id'] ?? '').toString();
    final isUser1 = myId != null && u1Id == myId;

    final partnerData = isUser1 ? match['user_2'] : match['user_1'];
    if (partnerData is Map) {
      final p = Map<String, dynamic>.from(partnerData);
      match['partner_name'] =
          (p['name'] ?? p['full_name'] ?? 'Runner').toString();
      match['partner_id'] = isUser1 ? u2Id : u1Id;
    } else {
      match['partner_name'] = 'Runner';
      match['partner_id'] = isUser1 ? u2Id : u1Id;
    }
  }

  // ── Public methods ─────────────────────────────────────────────────────────

  Future<void> fetchCandidates() async {
    _loadingCandidates = true;
    _candidatesError = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      _candidates = await _api.getCandidates(token: token);
    } catch (e) {
      _candidatesError = e.toString();
    } finally {
      _loadingCandidates = false;
      notifyListeners();
    }
  }

  Future<void> fetchMatches() async {
    _loadingMatches = true;
    _matchesError = null;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final myId = await _getMyUserId();
      final all = await _api.getMyMatches(token: token);

      final pending = <Map<String, dynamic>>[];
      final accepted = <Map<String, dynamic>>[];

      for (final m in all) {
        _enrichWithPartner(m, myId);
        if (m['status'] == 'accepted') {
          accepted.add(m);
        } else if (m['status'] == 'pending') {
          pending.add(m);
        }
      }

      _pendingMatches = pending;
      _acceptedMatches = accepted;
    } catch (e) {
      _matchesError = e.toString();
    } finally {
      _loadingMatches = false;
      notifyListeners();
    }
  }

  Future<bool> sendMatchRequest(String userId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final result =
          await _api.sendMatchRequest(userId2: userId, token: token);
      if (result.isNotEmpty) {
        _candidates.removeWhere(
          (c) => (c['user_id'] ?? c['id'] ?? '').toString() == userId,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _matchesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptMatch(String matchId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final success = await _api.accept(matchId, token: token);
      if (success) {
        final idx =
            _pendingMatches.indexWhere((m) => m['id'] == matchId);
        if (idx != -1) {
          final match = _pendingMatches.removeAt(idx);
          match['status'] = 'accepted';
          _acceptedMatches.insert(0, match);
        } else {
          _pendingMatches.removeWhere((m) => m['id'] == matchId);
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _matchesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectMatch(String matchId) async {
    try {
      final token = await _storage.readToken();
      if (token == null) throw Exception('Token not found');
      final success = await _api.reject(matchId, token: token);
      if (success) {
        _pendingMatches.removeWhere((m) => m['id'] == matchId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _matchesError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _matchesError = null;
    _candidatesError = null;
    notifyListeners();
  }
}
