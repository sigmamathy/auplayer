import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'album.dart';
import 'queue.dart';
import 'audio_player_handler.dart';

void main() async {

	// setup audio serivce.
	AudioPlayerHandler.instance = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.auplayer.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

	// load files from main storage.
	await AlbumPageState.refreshFiles();	

	// run app!
  runApp(
		MaterialApp(
			debugShowCheckedModeBanner: false,
			initialRoute: '/album',
			onGenerateRoute: (settings) {
				switch (settings.name) {
					case '/album':
						return PageRouteBuilder(pageBuilder: (_, __, ___) => AlbumPage());
					case '/queue':
						return PageRouteBuilder(pageBuilder: (_, __, ___) => QueuePage());
				}
				return null;
			},
		)
	);
}
