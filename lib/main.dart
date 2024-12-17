import 'package:flutter/material.dart';
import 'album.dart';
import 'queue.dart';

void main() async
{
	await AlbumPageState.refreshFiles();	
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
