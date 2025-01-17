import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:auplayer/pages/album.dart';
import 'package:auplayer/pages/queue.dart';
import 'package:auplayer/tools/audio_player_handler.dart';
import 'package:auplayer/tools/file_manager.dart';

void main() async {

	// setup audio serivce.
	AudioPlayerHandler.instance = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.auplayer.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
			androidStopForegroundOnPause: true,
    ),
  );

	final fm = FileManager.instance = FileManager();
	await fm.init();

	// run app!
  runApp(
		MaterialApp(
			debugShowCheckedModeBanner: false,
			theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF512DA8),
          brightness: Brightness.dark,
        ),
      ),
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

