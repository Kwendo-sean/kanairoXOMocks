/// Turns any thrown object into something safe to put in front of a user.
///
/// Raw exceptions leak internals — `ClientException` carries the request URL,
/// so a failed profile load was printing the API host on screen. Nothing from
/// the original message is ever passed through here; the text returned is
/// chosen from the kind of failure, never quoted from it.
library;

const String kOfflineMessage =
    'No internet connection. Check your connection and try again.';
const String kGenericMessage = 'Sorry, something went wrong.';
const String kSessionExpiredMessage =
    'Your session has expired. Please log in again.';

/// Whether [e] looks like the device being unable to reach the network at all,
/// as opposed to the server answering with an error.
bool isOfflineError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('connection reset') ||
      s.contains('connection error') ||
      s.contains('no address associated') ||
      s.contains('timeoutexception') ||
      s.contains('connectiontimeout') ||
      s.contains('receivetimeout') ||
      s.contains('sendtimeout');
}

bool isAuthError(Object e) {
  final s = e.toString();
  return s.contains('401') ||
      s.toLowerCase().contains('unauthorized') ||
      s.contains('AuthException');
}

/// The message to show. Never contains any part of [e].
String friendlyError(Object e) {
  if (isOfflineError(e)) return kOfflineMessage;
  if (isAuthError(e)) return kSessionExpiredMessage;
  return kGenericMessage;
}

const String kBadCredentialsMessage =
    'Incorrect email/phone or password.';

/// For sign-in specifically, where a 401 means the credentials were wrong
/// rather than that a session lapsed.
String friendlySignInError(Object e) {
  if (isOfflineError(e)) return kOfflineMessage;
  if (isAuthError(e)) return kBadCredentialsMessage;
  return kGenericMessage;
}
