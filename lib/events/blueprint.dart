import 'package:flutter/widgets.dart';

/// Notifies when the blueprint has to be saved.
/// Called when:
/// - a node is added, removed, or moved (on mouse release)
/// - a node is renamed (on text field submit)
/// - a node parameter value is changed (on text field submit)
/// - a node parameter is added, removed (on mouse release)
/// - a node parameter is linked, unlinked (on mouse release)
/// - a node link bend point is added, removed, moved (on mouse release)
class AutoSaveNotification extends Notification {}
