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
		player.playbackEventStream.listen((e) async {
			if (e.processingState == ProcessingState.completed) {
				if (allSongsCompleted) {
					await stop();
					return;
				}
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

	bool get allSongsCompleted => crntPos == -1 ||
		(crntPos == lastIndex && player.position >= player.duration!);

  Future<void> addMusic(FileInfo fi) async {
		MediaItem mi = MediaItem(id: fi.path, title: fi.name);
		if (allSongsCompleted) {
			player.setFilePath(fi.path);
			crntPos++;
			mediaItem.add(mi);
		}
		playlist.add(mi);
    queue.add(playlist);
  }

	Future<void> removeMusicAt(int index) async {
		playlist.removeAt(index);
		queue.add(playlist);
		if (playlist.isEmpty) {
			await stop();
			crntPos = -1;
			mediaItem.add(null);
		} else if (index == crntPos) {
			int i = index > lastIndex ? lastIndex : index;
			skipToQueueItem(i);
		} else if (index < crntPos) {
			crntPos--;
		}
	}

	Future<void> removeAll() async {
		await stop();
		playlist.clear();
		crntPos = -1;
		queue.add(playlist);
		mediaItem.add(null);
	}

	Future<void> moveMusicAt(int from, int to) async {
		int i = crntPos;
		if (to > from) to--;
		MediaItem item = playlist[from];
		playlist..remove(item)..insert(to, item);
		queue.add(playlist);
		if (i == from) {
			crntPos = to;
		} else if (i == to) {
			crntPos = from;
		}
		
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

  @override Future<void> stop() async {
		await player.stop();
	}

  @override Future<void> seek(Duration position) async => await player.seek(position);

  @override Future<void> skipToQueueItem(int index) async {
		bool shouldPlay = player.playing;
		await stop();
		crntPos = index;
		// await player.setFilePath(playlist[index].id);
		mediaItem.add(playlist[index]);
		await player.setFilePath(playlist[index].id);
		if (shouldPlay) play();
	}

	@override Future<void> skipToPrevious() async => await skipToQueueItem(crntPos - 1);
	@override Future<void> skipToNext() async => await skipToQueueItem(crntPos + 1);
}

Stream<MediaState> get mediaStateStream =>
  Rx.combineLatest3<MediaItem?, Duration, List<MediaItem>, MediaState>(
    AudioPlayerHandler.instance.mediaItem,
    AudioService.position,
		AudioPlayerHandler.instance.queue,
    (mediaItem, position, _) => MediaState(mediaItem, position)
  );

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
