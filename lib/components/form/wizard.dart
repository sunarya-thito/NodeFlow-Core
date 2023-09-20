import 'package:flutter/material.dart';
import 'package:nodeflow/components/form/form.dart';
import 'package:nodeflow/components/page_holder.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

class WizardPage {
  final Widget title;
  final FormData form;
  final NextAction Function(FormData form) next;

  const WizardPage({
    required this.title,
    required this.form,
    required this.next,
  });
}

abstract class NextAction {
  final bool enabled;
  const NextAction({this.enabled = true});
}

/// Hides the next button temporarily
class UnknownAction extends NextAction {
  const UnknownAction({super.enabled = false});
}

/// Shows the finish button
class FinishAction extends NextAction {
  const FinishAction({super.enabled = true});
}

/// Shows the next button
class NextPageAction extends NextAction {
  final WizardPage page;
  const NextPageAction(this.page, {super.enabled});
}

class Wizard extends StatefulWidget {
  final WizardPage home;
  final Widget? nextButtonLabel;
  final Widget? backButtonLabel;
  final Widget? cancelButtonLabel;
  final Widget? finishButtonLabel;
  final void Function(FormData form)? onFinish;
  final void Function()? onCancel;

  const Wizard({
    Key? key,
    required this.home,
    this.nextButtonLabel,
    this.backButtonLabel,
    this.finishButtonLabel,
    this.cancelButtonLabel,
    this.onFinish,
    this.onCancel,
  }) : super(key: key);

  @override
  _WizardState createState() => _WizardState();
}

class _WizardState extends State<Wizard> {
  final List<WizardPage> history = [];

  @override
  void initState() {
    super.initState();
    _pushHistory(widget.home);
  }

  void _pushHistory(WizardPage page) {
    WizardPage? old = history.lastOrNull;
    if (old != null) {
      old.form.removeListener(_update);
    }
    history.add(page);
    _subNavigatorKey.currentState?.go(FormView(
      title: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          color: app.primaryTextColor,
          decoration: TextDecoration.none,
        ),
        child: page.title,
      ),
      form: page.form,
    ));
    page.form.addListener(_update);
  }

  void _pullHistory() {
    if (history.length <= 1) return;
    WizardPage old = history.removeLast();
    old.form.removeListener(_update);
    _subNavigatorKey.currentState?.goBack();
    WizardPage page = history.last;
    page.form.addListener(_update);
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant Wizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.home != widget.home) {
      history.clear();
      history.add(widget.home);
    }
  }

  final GlobalKey<SubNavigatorState> _subNavigatorKey = GlobalKey<SubNavigatorState>();

  @override
  Widget build(BuildContext context) {
    WizardPage page = history.first;
    NextAction? action = history.lastOrNull?.next(history.last.form);
    return Column(
      children: [
        Expanded(
          child: SubNavigator(
            key: _subNavigatorKey,
            home: FormView(
              title: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  color: app.primaryTextColor,
                  decoration: TextDecoration.none,
                ),
                child: page.title,
              ),
              form: page.form,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: joinWidgets([
              OutlinedButton(
                onPressed: history.length > 1
                    ? () {
                        setState(() {
                          _pullHistory();
                        });
                      }
                    : widget.onCancel,
                child: history.length > 1 ? widget.backButtonLabel ?? Text(i18n.wizardBack) : widget.cancelButtonLabel ?? Text(i18n.wizardCancel),
              ),
              if (action is NextPageAction)
                ElevatedButton(
                    onPressed: action.enabled
                        ? () {
                            setState(() {
                              _pushHistory(action.page);
                            });
                          }
                        : null,
                    child: widget.nextButtonLabel ?? Text(i18n.wizardNext)),
              if (action is FinishAction)
                ElevatedButton(
                  onPressed: action.enabled
                      ? () {
                          if (widget.onFinish != null) widget.onFinish!(history.last.form);
                        }
                      : null,
                  child: widget.finishButtonLabel ?? Text(i18n.wizardDone),
                ),
            ], () => const SizedBox(width: 8)),
          ),
        )
      ],
    );
  }
}
