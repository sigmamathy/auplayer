import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'app_bar.dart';
import 'navigate_panel.dart';

class QueuePage extends StatefulWidget {
	const QueuePage({ super.key });
	@override State<StatefulWidget> createState() => QueuePageState();
}

class QueuePageState extends State<QueuePage> {

	static List<String> musicQueue = [];
	static final player = AudioPlayer();
	static bool isPlaying = false;
	static int crntPos = 0;

	@override
  void initState() {
		super.initState();
		player.playerStateStream.listen((state) async {
			if (state.processingState == ProcessingState.completed) {
				++crntPos;
				if (crntPos < musicQueue.length) {
					await player.setFilePath(musicQueue[crntPos]);
					player.play();
				} else {
					isPlaying = false;
				}
				setState(() {});
			}
		});
  }

	static void addAudio(String path) async {
		musicQueue.add(path);
		if (musicQueue.length - 1 == crntPos) {
			await player.setFilePath(musicQueue[crntPos]);
		}
	}

	static void switchPlay() {
		if (isPlaying) {
			player.pause();
			isPlaying = false;
		} else {
			player.play();
			isPlaying = true;
		}
	}

	@override
  Widget build(BuildContext context) {
    return Scaffold(
			backgroundColor: Colors.grey[800],
			appBar: CommonAppBar(onRefresh: (){}),
			body: Column(
				children: [
					Expanded(
						child: IconButton(
							icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color:Colors.white),
							onPressed: () async {
								switchPlay();
								setState(() {});
							}
						)
					),
					NavigatePanel(1)
				]
			),
		);
  }
}
