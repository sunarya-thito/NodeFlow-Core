import 'package:flutter/material.dart';
import 'package:nodeflow/components/page_holder.dart';

class DashboardCategory {
  final String Function() label;
  final List<DashboardPage> pages;

  DashboardCategory({required this.label, required this.pages});
}

class DashboardPage {
  final ValueKey<String> key;
  final Icon icon;
  final String Function() label;
  final Widget Function(BuildContext context)? pageBuilder;
  final void Function()? onTap;
  final GlobalKey<SubNavigatorState> navigatorKey = GlobalKey();

  DashboardPage({required this.key, required this.icon, required this.label, this.pageBuilder, this.onTap});
}
