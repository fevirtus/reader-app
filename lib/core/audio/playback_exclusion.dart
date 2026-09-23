/// Shared only for mutual exclusion; V1 and Audio book keep separate state.
class PlaybackExclusion {
  static Future<void> Function()? stopAudioBook;
  static Future<void> Function()? pauseAudioBook;
}
