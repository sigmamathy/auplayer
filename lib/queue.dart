import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'app_bar.dart';
import 'navigate_panel.dart';
import 'audio_player_handler.dart';

class QueuePage extends StatefulWidget {
	const QueuePage({ super.key });
	@override State<StatefulWidget> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {

	Widget _mediaTitle() {
		return StreamBuilder<MediaItem?>(
			stream: AudioPlayerHandler.instance.mediaItem,
      builder: (context, snapshot) {
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

	Widget _mediaControlBar() {
    return StreamBuilder<bool>(
      stream: AudioPlayerHandler.instance.playbackState.map((state) => state.playing), 
      builder: (context, snapshot) {
        bool isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
						IconButton(
							onPressed: AudioPlayerHandler.instance.skipToPrevious,
							icon: Icon(Icons.skip_previous, color: Colors.white)
						),
            IconButton(
              onPressed: isPlaying ? AudioPlayerHandler.instance.pause : AudioPlayerHandler.instance.play, 
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
							iconSize: 36.0,
            ),
						IconButton(
							onPressed: AudioPlayerHandler.instance.skipToNext,
							icon: Icon(Icons.skip_next, color: Colors.white)
						),
          ],
        );
      }
    );
	}

	Widget _mediaProgressBar() {
    return StreamBuilder<MediaState>(
      stream: mediaStateStream,
      builder: (context, snapshot) {
        final mediaState = snapshot.data;
        Duration dur = mediaState?.mediaItem?.duration ?? Duration.zero;
        Duration pos = mediaState?.position ?? Duration.zero;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
						Text(durationToTime(pos), style: TextStyle(color: Colors.white)),
            Expanded(
							child: Slider(
								min: 0,
								max: dur.inSeconds.toDouble(),
								value: pos.inSeconds.toDouble(), 
								thumbColor: Colors.deepPurple[400],
								activeColor: Colors.deepPurple[400],
								inactiveColor: Colors.grey,
								onChanged: (newValue) {
									AudioPlayerHandler.instance.seek(Duration(seconds: newValue.toInt()));
								}
							)
						),
						Text(durationToTime(dur), style: TextStyle(color: Colors.white)),
          ],
        );
      },
    );
  }

	Widget _queueList() {
		return StreamBuilder(
			stream: AudioPlayerHandler.instance.queue, 
			builder: (context, snapshot) {
				final queue = snapshot.data ?? [];

				return Expanded(
					child: SingleChildScrollView(
						child: Column(
							children: [...queue.asMap().entries.map((entry) => 
								Card(
									color: Colors.black,
									child: ListTile(
										leading: Text((entry.key+1).toString(), style: TextStyle(color: Colors.white)),
										title: Text(entry.value.title, style: TextStyle(color: Colors.white)),
										trailing: IconButton(icon: Icon(Icons.delete), color: Colors.white, onPressed: (){}),
									)),
								)
							],
						)
					)
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
					Card(
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
					),
					Expanded(
						child: Card(
							margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
							color: Colors.grey[850],
							child: Padding(
							padding: EdgeInsets.all(10),
								child: Column(
									children: [
										Text(
											"Music Queue",
											style: TextStyle(
												fontSize: 16.0,
												fontWeight: FontWeight.bold,
												color: Colors.white
											)
										),
										Divider(color: Colors.grey[800], height: 20.0),
										_queueList()
									]
								)
							)
						)
					),
					NavigatePanel(1)
				]
			),
		);
  }

	String durationToTime(Duration duration) {
		String ng = duration.isNegative ? '-' : '';

		String td(int n) => n.toString().padLeft(2, "0");
		String tdm = td(duration.inMinutes.remainder(60).abs());
		String tds = td(duration.inSeconds.remainder(60).abs());
		return "$ng${duration.inHours > 0 ? "${td(duration.inHours)}:" : ""}$tdm:$tds";
	}
}

