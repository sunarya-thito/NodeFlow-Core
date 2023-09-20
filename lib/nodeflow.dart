import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nodeflow/app_settings.dart';
import 'package:nodeflow/compact_ui.dart';
import 'package:nodeflow/components/dashboard/dashboard.dart';
import 'package:nodeflow/components/debug/debug_focus_highlighter.dart';
import 'package:nodeflow/components/state_delivery.dart';
import 'package:nodeflow/project/project_manager.dart';
import 'package:nodeflow/router.dart';

import 'module/module.dart';

class Nodeflow extends StatefulWidget {
  final List<RouterPath> initialPath;
  final List<ProjectModule> modules;

  const Nodeflow({
    Key? key,
    required this.modules,
    this.initialPath = const [KeyPath('dashboard')],
  }) : super(key: key);

  @override
  NodeflowState createState() => NodeflowState();

  static NodeflowState of(BuildContext context) {
    return StateData.of<NodeflowState>(context);
  }
}

class NodeflowState extends State<Nodeflow> {
  @override
  Widget build(BuildContext context) {
    return StateData(
      state: this,
      child: DebugFocusHighlighter(
        enabled: false,
        child: ProjectManager(
          directory: Directory('projects'),
          modules: widget.modules,
          child: AppSettings(
            file: {},
            child: RouterNavigator(
              initialPaths: widget.initialPath,
              child: CompactUI(
                mode: ThemeMode.dark,
                child: RouteBuilder(
                  routes: {
                    DefaultPathRequest: (path) => const RedirectRouterPage([KeyPath('dashboard')]),
                    KeyPathRequest('dashboard'): (path) {
                      return RouterPageBuilder((context) => const Dashboard());
                    },
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
