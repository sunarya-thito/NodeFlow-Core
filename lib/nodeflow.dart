import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nodeflow/compact_ui.dart';
import 'package:nodeflow/pages/editor.dart';

class Nodeflow extends StatefulWidget {
  const Nodeflow({Key? key}) : super(key: key);

  @override
  _NodeflowState createState() => _NodeflowState();
}

class _NodeflowState extends State<Nodeflow> {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Editor(),
        routes: [
          GoRoute(
            path: 'license',
            builder: (context, state) => Container(),
            routes: [
              GoRoute(
                path: 'activate',
                builder: (context, state) => Container(),
              ),
            ],
          ),
          GoRoute(
              path: 'project',
              builder: (context, state) {
                return Container();
              },
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    return Container();
                  },
                )
              ]),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return CompactUI(mode: ThemeMode.dark, routerConfig: _router);
  }
}
