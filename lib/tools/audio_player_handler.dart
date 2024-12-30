import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:auplayer/tools/file_manager.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {

	// Singleton instance.
	static late AudioPlayerHandler instance;

	List<MediaItem> playlist = [];
	int crntPos = -1;

	final player = AudioPlayer(); 

	AudioPlayerHandler() {
		// listen duration changes.
    player.durationStream.listen((duration) {
      int index = player.currentIndex ?? -1;
      final nq = queue.value;
      if (index == -1 || nq.isEmpty) {
				mediaItem.add(null);
				return;
			}
      final m = nq[index].copyWith(duration: duration);
      nq[index] = m;
      queue.add(nq);
      mediaItem.add(m);
    });

		// skip to next song if available.
		player.playbackEventStream.listen((e) {
			if (e.processingState == ProcessingState.completed && crntPos < playlist.length - 1) {
				skipToNext();
			}
		});

		player.playbackEventStream.map(_transformEvent).pipe(playbackState);
	}

	PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (!isAtFirstMusic()) MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        if (!isAtLastMusic()) MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
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

  Future<void> addMusic(FileInfo fi) async {
		MediaItem mi = MediaItem(id: fi.path, title: fi.name);
		playlist.add(mi);
		if (player.audioSource == null) {
			player.setFilePath(fi.path);
		}
    queue.value.add(mi);
    queue.add(queue.value);
  }

	Future<void> removeMusicAt(int index) async {
		
		await playlist.removeAt(index);
		final nq = queue.value..removeAt(index);
		queue.add(nq);
		if (playlist.length == 0) {
			mediaItem.add(null);
			await pause();
		}
	}

	Future<void> removeAll() async {
		await playlist.clear();
		final nq = queue.value..clear();
		queue.add(nq);
		mediaItem.add(null);
		await pause();
	}

	Future<void> moveMusicAt(int from, int to) async {
		if (to > from) to--;
		int i = crntIndex();
		Duration pos = player.position;
		await playlist.move(from, to);
		final a = queue.value[from];
		queue.value..remove(a)..insert(to, a);
		queue.add(queue.value);
		if (i == from) {
			await player.seek(pos, index: to);
			mediaItem.add(queue.value[to]);
		} else if (i == to) {
			await player.seek(pos, index: from);
			mediaItem.add(queue.value[from]);
		}
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
