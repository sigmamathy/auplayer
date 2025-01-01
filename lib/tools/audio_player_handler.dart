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
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });

		// skip to next song if available.
		player.playbackEventStream.listen((e) {
			if (e.processingState == ProcessingState.completed) {
				skipToNext();
			}
		});

		player.playbackEventStream.map(_transformEvent).pipe(playbackState);
	}

	PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (crntPos > 0) MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        if (crntPos < lastIndex) MediaControl.skipToNext,
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
      queueIndex: crntPos,
    );
  }

	int get lastIndex => playlist.length - 1;

  Future<void> addMusic(FileInfo fi) async {
		MediaItem mi = MediaItem(id: fi.path, title: fi.name);
		playlist.add(mi);
		if (player.audioSource == null) {
			player.setFilePath(fi.path);
			crntPos = 0;
			mediaItem.add(mi);
		}
    queue.value.add(mi);
    queue.add(queue.value);
  }

	Future<void> removeMusicAt(int index) async {
		playlist.removeAt(index);
		final nq = queue.value..removeAt(index);
		queue.add(nq);
		if (index == crntPos) {
			int i = index > lastIndex ? lastIndex : index;
			skipToQueueItem(i);
		}
	}

	Future<void> removeAll() async {
		await stop();
		playlist.clear();
		final nq = queue.value..clear();
		queue.add(nq);
		mediaItem.add(null);
	}

	Future<void> moveMusicAt(int from, int to) async {
		// if (to > from) to--;
		// int i = crntIndex();
		// Duration pos = player.position;
		// await playlist.move(from, to);
		// final a = queue.value[from];
		// queue.value..remove(a)..insert(to, a);
		// queue.add(queue.value);
		// if (i == from) {
		// 	await player.seek(pos, index: to);
		// 	mediaItem.add(queue.value[to]);
		// } else if (i == to) {
		// 	await player.seek(pos, index: from);
		// 	mediaItem.add(queue.value[from]);
		// }
	}
  
  // The most common callbacks:
  @override Future<void> play() async => await player.play();
  @override Future<void> pause() async => await player.pause();
  @override Future<void> stop() async => await player.stop();
  @override Future<void> seek(Duration position) async => await player.seek(position);

  @override Future<void> skipToQueueItem(int index) async {
		bool shouldPlay = player.playing;
		await stop();
		crntPos = index;
		if (index >= 0 && index <= lastIndex) {
			await player.setFilePath(playlist[index].id);
			// ----------------------------------------------------- THIS DOES NOT WORK GOD DAMMIT ------------------------------ //
			mediaItem.add(MediaItem(id: playlist[index].id, title: playlist[index].title));
			if (shouldPlay) play();
		} else {
			mediaItem.add(null);
		}
	}

	@override Future<void> skipToPrevious() => skipToQueueItem(crntPos - 1);
	@override Future<void> skipToNext() => skipToQueueItem(crntPos + 1);
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
