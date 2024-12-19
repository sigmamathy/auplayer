import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'album.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {

	static late AudioPlayerHandler instance;
	final player = AudioPlayer(); 
	final playlist = ConcatenatingAudioSource(children: []);

	AudioPlayerHandler() {
		player.setAudioSource(playlist);
		_listenForDurationChanges();
		player.playbackEventStream.map(_transformEvent).pipe(playbackState);
	}

	void _listenForDurationChanges() {
    player.durationStream.listen((duration) {
      int index = player.currentIndex ?? -1;
      final newQueue = queue.value;
      if (index == -1 || newQueue.isEmpty) return;
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

	PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  MediaItem toMediaItem(FileInfo fi) {
    return MediaItem(
      id: fi.path, 
      title: fi.filename,
    );
  }

  Future<void> addSongToQueue(FileInfo fi) async {
    final UriAudioSource source = AudioSource.file(fi.path);
    playlist.add(source);

    queue.value.add(toMediaItem(fi));
    queue.add(queue.value);
  }
  
  // The most common callbacks:
  @override Future<void> play() => player.play();
  @override Future<void> pause() => player.pause();
  @override Future<void> stop() => player.stop();
  @override Future<void> seek(Duration position) => player.seek(position);
  @override Future<void> skipToQueueItem(int index) => player.seek(Duration.zero, index: index);
}

Stream<MediaState> get mediaStateStream =>
  Rx.combineLatest2<MediaItem?, Duration, MediaState>(
    AudioPlayerHandler.instance.mediaItem,
    AudioService.position,
    (mediaItem, position) => MediaState(mediaItem, position)
  );

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
