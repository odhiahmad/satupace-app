import 'dart:convert';
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

  // Current user's id (available after fetchMatches / fetchCandidates)
  String? get myUserId => _myUserId;

  // Backward-compat aliases
  bool get loading => _loadingMatches;
  String? get error => _matchesError;
  List<Map<String, dynamic>> get matches => _acceptedMatches;

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<String?> _getMyUserId() async {
    if (_myUserId != null && _myUserId!.isNotEmpty) return _myUserId;

    // 1. Try secure storage
    final stored = await _storage.readUserId();
    if (stored != null && stored.isNotEmpty) {
      _myUserId = stored;
      return _myUserId;
    }

    // 2. Fallback: decode JWT claim
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
          switch (payload.length % 4) {
            case 2: payload += '=='; break;
            case 3: payload += '='; break;
            default: break;
          }
          final decoded = jsonDecode(
            utf8.decode(base64Decode(payload)),
          ) as Map<String, dynamic>;
          final jwtUid =
              decoded['user_id']?.toString() ?? decoded['sub']?.toString();
          if (jwtUid != null && jwtUid.isNotEmpty) {
            _myUserId = jwtUid;
            await _storage.writeUserId(jwtUid);
            return _myUserId;
          }
        }
      } catch (_) {}
    }

    return null;
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

    // Verification photo is only present when match is accepted
    match['partner_verification_photo'] = isUser1
        ? match['user_2_verification_photo']
        : match['user_1_verification_photo'];
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
      debugPrint('[MATCH] myUserId=$myId');
      final all = await _api.getMyMatches(token: token);
      debugPrint('[MATCH] total matches from API: ${all.length}');

      final pending = <Map<String, dynamic>>[];
      final accepted = <Map<String, dynamic>>[];

      for (final m in all) {
        _enrichWithPartner(m, myId);
        debugPrint('[MATCH] id=${m['id']} status=${m['status']} u1=${m['user_1_id']} u2=${m['user_2_id']} partner=${m['partner_name']}');
        if (m['status'] == 'accepted') {
          accepted.add(m);
        } else if (m['status'] == 'pending') {
          pending.add(m);
        }
      }
      debugPrint('[MATCH] pending=${pending.length} accepted=${accepted.length}');

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
