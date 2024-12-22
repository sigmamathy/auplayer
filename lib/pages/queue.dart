import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:auplayer/navigate_panel.dart';
import 'package:auplayer/tools/audio_player_handler.dart';

class QueuePage extends StatefulWidget {
	const QueuePage({ super.key });
	@override State<StatefulWidget> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {

	Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
		return AnimatedBuilder(
			animation: animation,
			builder: (BuildContext context, Widget? child) {
				final double animValue = Curves.easeInOut.transform(animation.value);
				final double elevation = lerpDouble(1, 6, animValue)!;
				final double scale = lerpDouble(1, 1.02, animValue)!;
				return Transform.scale(
					scale: scale,
					// Create a Card based on the color and the content of the dragged one
					// and set its elevation to the animated value.
					child: Card(
						elevation: elevation,
						color: Colors.black,
						child: Text("hi"),
					),
				);
			},
			child: child,
		);
	}

	Widget _queueList() {
		final ah = AudioPlayerHandler.instance;
		return StreamBuilder(
			stream: ah.queue, 
			builder: (_, s1) {
				final queue = s1.data ?? [];
				return StreamBuilder(
					stream: ah.player.currentIndexStream,
					builder: (_, s2) {
						return Expanded(
							child: ReorderableListView(
								onReorder: (a, b) async {
									if (a == b) return;
									await ah.moveMusicAt(a, b);
								},
								proxyDecorator: proxyDecorator,
								children: [...queue.asMap().entries.map(
									(entry) => _QueueMusicCard(entry.key, entry.value.title, key: Key('$entry.key')))
								],
							)
						);
					}
				);
			}
		);
	}

	@override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: AppBar(
				title: Row(
					children: [
						Text("auplayer",
							style: TextStyle(
								color: Colors.white,
								fontFamily: 'RougeScript', 
								fontWeight: FontWeight.bold,
								fontSize: 30.0
							)
						),
						Expanded(child: SizedBox()),
						PopupMenuButton<int>(
							onSelected: (int value) async {
								switch (value) {
									case 0:
										AudioPlayerHandler.instance.removeAll();
										break;
								}
							},
							itemBuilder: (BuildContext context) {
								return <PopupMenuEntry<int>>[
									PopupMenuItem<int>(
										value: 0,
										child: Text('Clear All'),
									),
									PopupMenuItem<int>(
										value: 1,
										child: Text('Set As Home'),
									),
									PopupMenuItem<int>(
										value: 2,
										child: Text('Option 3'),
									),
								];
							},
							child: Icon(Icons.more_vert, color: Colors.white),
						),
					]
				),
				backgroundColor: Colors.deepPurple[700],
			),
			body: Column(
				children: [
					_MediaPlayerWidget(),
					Expanded(
						child: Card(
							margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
							color: Colors.grey[850],
							child: Padding(
								padding: EdgeInsets.all(10),
								child: _queueList(),
							)
						)
					),
					NavigatePanel(1)
				]
			),
		);
  }
}

class _MediaPlayerWidget extends StatelessWidget {

	Widget _mediaTitle() {
		return StreamBuilder<MediaItem?>(
			stream: AudioPlayerHandler.instance.mediaItem,
      builder: (_, snapshot) {
        String title = snapshot.data?.title ?? "No Song In Queue";
        return Text(
					title,
					style: TextStyle(
						color: Colors.white,
						fontSize: 16.0,
						fontWeight: FontWeight.bold,
					)
				);
      }
		);
	}

	Widget _mediaProgressBar() {
		final ah = AudioPlayerHandler.instance;
    return StreamBuilder<MediaState>(
      stream: mediaStateStream,
      builder: (_, __) {
				Duration dur = ah.player.duration ?? Duration.zero;	
				Duration pos = ah.playlist.length > 0 ? ah.player.position : Duration.zero;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
						Text(_durationToTime(pos), style: TextStyle(color: Colors.white)),
            Expanded(
							child: Slider(
								min: 0,
								max: dur.inSeconds.toDouble(),
								value: pos.inSeconds.toDouble(), 
								thumbColor: Colors.deepPurple[400],
								activeColor: Colors.deepPurple[400],
								inactiveColor: Colors.grey,
								onChanged: (newValue) {
									ah.seek(Duration(seconds: newValue.toInt()));
								}
							)
						),
						Text(_durationToTime(dur), style: TextStyle(color: Colors.white)),
          ],
        );
      },
    );
  }
	
	Widget _mediaControlBar() {
		final ah = AudioPlayerHandler.instance;
    return StreamBuilder<bool>(
      stream: ah.playbackState.map((state) => state.playing), 
      builder: (_, s) {

        bool isPlaying = s.data ?? false;
				bool hasMedia = ah.mediaItem.value != null;
				bool canSkipPrev = hasMedia && (ah.player.currentIndex??-1) > 0;
				bool canSkipNext = hasMedia && (ah.player.currentIndex??-1) < ah.playlist.length-1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
						IconButton(
							onPressed: canSkipPrev ? ah.skipToPrevious : (){},
							icon: Icon(
								Icons.skip_previous,
								color: canSkipPrev ? Colors.white : Colors.grey
							)
						),
            IconButton(
              onPressed: hasMedia ? (isPlaying ? ah.pause : ah.play) : (){}, 
              icon: Icon(
								isPlaying ? Icons.pause : Icons.play_arrow,
								color: hasMedia ? Colors.white : Colors.grey
							),
							iconSize: 36.0,
            ),
						IconButton(
							onPressed: canSkipNext ? ah.skipToNext : (){},
							icon: Icon(
								Icons.skip_next,
								color: canSkipNext ? Colors.white : Colors.grey
							)
						),
          ],
        );
      }
    );
	}

	@override
  Widget build(BuildContext context) {
		return Card(
			margin: EdgeInsets.all(10.0),
			color: Colors.grey[850],
			child: Padding(
				padding: EdgeInsets.all(10.0),
				child: Column(
					children: [
						_mediaTitle(),
						SizedBox(height: 10.0),
						_mediaProgressBar(),
						_mediaControlBar(),
					]
				)
			)
		);
  }
}

class _QueueMusicCard extends StatelessWidget {

	final int index;
	final String name;

	const _QueueMusicCard(this.index, this.name, { super.key });

	@override
  Widget build(BuildContext context) {
		final ah = AudioPlayerHandler.instance;
    return GestureDetector(
			onTap: () {
				if (ah.crntIndex() != index) {
					ah.skipToQueueItem(index);
				}
			},
			child: Card(
				color: Colors.black,
				child: ListTile(
					leading: Text(
						(index+1).toString(),
						style: TextStyle(color: Colors.white)
					),
					title: Text(
						name,
						style: TextStyle(
							color: ah.crntIndex() == index ? Colors.cyan : Colors.white
						)
					),
					trailing: IconButton(
						icon: Icon(Icons.delete),
						color: Colors.white,
						onPressed: (){
							ah.removeMusicAt(index);
						}
					),
				)
			),
		);
  }
}

String _durationToTime(Duration duration) {
	String ng = duration.isNegative ? '-' : '';

	String td(int n) => n.toString().padLeft(2, "0");
	String tdm = td(duration.inMinutes.remainder(60).abs());
	String tds = td(duration.inSeconds.remainder(60).abs());
	return "$ng${duration.inHours > 0 ? "${td(duration.inHours)}:" : ""}$tdm:$tds";
}
