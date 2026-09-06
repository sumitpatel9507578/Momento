import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> initialize() async {
    await _googleSignIn.initialize();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google ID token was not returned.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      throw Exception(
        'Google Sign-In failed: '
        '${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
