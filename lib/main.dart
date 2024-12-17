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
			routes: {
				'/album': (ctx) => AlbumPage(),
				'/queue': (ctx) => QueuePage(),
			}
		)
	);
}
