import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'app_bar.dart';
import 'navigate_panel.dart';

class QueuePage extends StatefulWidget {
	const QueuePage({ super.key });
	@override State<StatefulWidget> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {

	static late AudioPlayerHandler handler;

	static List<String> musicQueue = [];
	static int crntPos = 0;

	static Future<void> addAudio(String path) async {
		musicQueue.add(path);
		if (musicQueue.length - 1 == crntPos) {
			await handler.loadAudioCrntPos();
		}
	}

	Widget _mediaControlBar() {
    return StreamBuilder<bool>(
      stream: handler.playbackState.map((state) => state.playing), 
      builder: (context, snapshot) {
        bool isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: isPlaying ? handler.pause : handler.play, 
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            ),
          ],
        );
      }
    );
	}

	@override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: CommonAppBar(onRefresh: (){}),
			body: Column(
				children: [
					Expanded(
						child: _mediaControlBar()
					),
					NavigatePanel(1)
				]
			),
		);
  }
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {

	final _player = AudioPlayer(); // e.g. just_audio

	AudioPlayerHandler() {
		_player.playbackEventStream.map(_transformEvent).pipe(playbackState);
		playbackState.listen((PlaybackState state) async {
			if (state.processingState == AudioProcessingState.completed) {
				int x = ++QueuePageState.crntPos;
				if (x < QueuePageState.musicQueue.length) {
					await loadAudioCrntPos();
					play();
				} else {
					// TODO: set state
				}
			}
		});
	}

	Future<void> loadAudioCrntPos() async {
    await _player.setFilePath(QueuePageState.musicQueue[QueuePageState.crntPos]);
	}

	PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
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
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
  
  // The most common callbacks:
  @override Future<void> play() => _player.play();
  @override Future<void> pause() => _player.pause();
  @override Future<void> stop() => _player.stop();
  @override Future<void> seek(Duration position) => _player.seek(position);
  @override Future<void> skipToQueueItem(int index) => _player.seek(Duration.zero, index: index);
}

Stream<MediaState> get mediaStateStream =>
  Rx.combineLatest2<MediaItem?, Duration, MediaState>(
    QueuePageState.handler.mediaItem,
    AudioService.position,
    (mediaItem, position) => MediaState(mediaItem, position)
  );

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}
