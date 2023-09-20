import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/i18n.dart';
import 'package:nodeflow/theme/compact_data.dart';
import 'package:nodeflow/ui_util.dart';

class FormData extends ValueNotifier<FormState> {
  final List<FormItem> fields;
  FormData(List<FormItem> fields)
      : fields = List.unmodifiable(fields),
        super(const FormState()) {
    List<FormItem> invalidFields = [];
    for (final field in fields) {
      if (field.value.invalidReason != null) {
        invalidFields.add(field);
      }
    }
    value = FormState(invalidFields: invalidFields);
  }

  bool get isValid => value.invalidFields.isEmpty;
}

class FormView extends StatefulWidget {
  final Widget title;
  final FormData form;
  final List<Widget>? buttons;

  const FormView({Key? key, required this.title, required this.form, this.buttons}) : super(key: key);

  @override
  _FormViewState createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  @override
  void initState() {
    super.initState();
    widget.form.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant FormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.form != widget.form) {
      oldWidget.form.removeListener(_update);
      widget.form.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.form.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: FormViewData(
          form: widget.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 18,
                  color: app.primaryTextColor,
                  fontFamily: 'Inter',
                ),
                child: widget.title,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FocusTraversalGroup(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final field = widget.form.fields[index];
                      return field.createWidget(widget.form);
                    },
                    itemCount: widget.form.fields.length,
                  ),
                ),
              ),
              if (widget.buttons != null) const SizedBox(height: 16),
              if (widget.buttons != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: joinWidgets(widget.buttons!, () => const SizedBox(width: 8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormViewData extends InheritedWidget {
  final FormData form;

  FormViewData({Key? key, required this.form, required Widget child}) : super(key: key, child: child);

  static FormViewData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FormViewData>()!;
  }

  @override
  bool updateShouldNotify(covariant FormViewData oldWidget) {
    return oldWidget.form != form;
  }
}

class FormState {
  final List<FormItem> invalidFields;

  const FormState({this.invalidFields = const []});

  bool get isValid => invalidFields.isEmpty;

  FormState copyWith(FormItem field) {
    return FormState(invalidFields: [...invalidFields, field]);
  }

  FormState copyWithout(FormItem field) {
    return FormState(invalidFields: invalidFields.where((f) => f != field).toList());
  }
}

typedef Validator<T> = Validation<T>? Function(T value);

extension ValidatorCombiner<T> on Validator<T> {
  Validator<T> combine(Validator<T> other) {
    return combineValidators([this, other]);
  }

  Validator<T> combineMultiple(List<Validator<T>> others) {
    return combineValidators([this, ...others]);
  }
}

abstract class Validation<T> {
  const Validation();
}

class ReplaceValidation<T> extends Validation<T> {
  final T value;

  const ReplaceValidation(this.value);
}

typedef Reason = String Function(AppLocalizations i18n);

class ReasonValidation<T> extends Validation<T> {
  final Reason reason;

  const ReasonValidation(this.reason);
}

class FormValue<T> {
  final T value;
  final Reason? invalidReason;

  const FormValue(this.value, [this.invalidReason]);

  FormValue<T> copyWithValueAndReason(T value, Reason? invalidReason) {
    return FormValue(value, invalidReason);
  }

  FormValue<T> copyWithValue(T value) {
    return FormValue(value, invalidReason);
  }

  FormValue<T> copyWithReason(Reason? invalidReason) {
    return FormValue(value, invalidReason);
  }
}

abstract class FormItem<T> extends ValueNotifier<FormValue<T>> {
  Validator<T>? _validator;

  FormItem(T value) : super(FormValue(value));

  FormItem<T> validate(Validator<T> validator) {
    _validator = validator;
    T value = this.value.value;
    Validation<T>? invalidReason = _validate(value);
    if (invalidReason is ReplaceValidation<T>) {
      this.value = FormValue(invalidReason.value, null);
    } else if (invalidReason is ReasonValidation<T>) {
      this.value = FormValue(value, invalidReason.reason);
    }
    return this;
  }

  Validation<T>? _validate(T value) {
    if (_validator != null) {
      final invalidReason = _validator!(value);
      return invalidReason;
    }
    return null;
  }

  Widget createWidget(FormData form);
}

enum ChildPosition {
  under,
  beside;
}

class StandardFieldWidget extends StatelessWidget {
  final Widget label;
  final Widget child;
  final String? invalidReason;
  final ChildPosition childPosition;

  const StandardFieldWidget({Key? key, required this.label, required this.child, this.invalidReason, this.childPosition = ChildPosition.under})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (childPosition == ChildPosition.under) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: label,
            ),
            const SizedBox(height: 8),
            child,
            if (invalidReason != null) ...[
              const SizedBox(height: 4),
              invalidReason!.asTextWidget(style: TextStyle(color: app(context).nodeErrorColor)),
            ],
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(
          top: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                label,
                const SizedBox(width: 16),
                Expanded(child: child),
              ],
            ),
            if (invalidReason != null) ...[
              const SizedBox(height: 4),
              invalidReason!.asTextWidget(style: TextStyle(color: app(context).nodeErrorColor)),
            ],
          ],
        ),
      );
    }
  }
}

Validator<String> validateMaxLength(int length) {
  return (value) {
    if (value.length > length) {
      return ReasonValidation((i18n) => '${value.length}/$length');
    }
    return null;
  };
}

Validator<String> validateTrimEndMaxLength(int length) {
  return (value) {
    if (value.length > length) {
      return ReplaceValidation(value.substring(0, length));
    }
    return null;
  };
}

Validator<String> validateTrimStartMaxLength(int length) {
  return (value) {
    if (value.length > length) {
      return ReplaceValidation(value.substring(value.length - length));
    }
    return null;
  };
}

Validator<String> validateTrimString() {
  return (value) {
    final trimmed = value.trim();
    return ReplaceValidation(trimmed);
  };
}

Validator<String> validateNotEmpty() {
  return (value) {
    if (value.trim().isEmpty) {
      return ReasonValidation((i18n) => i18n.formMustNotBeEmpty);
    }
    return null;
  };
}

Validator<dynamic> validateNotNull() {
  return (value) {
    if (value == null) {
      return ReasonValidation((i18n) => i18n.formMustNotBeEmpty);
    }
    return null;
  };
}

Validator<T> combineValidators<T>(List<Validator<T>> validators) {
  if (validators.isEmpty) {
    return (value) => null;
  }
  return (value) {
    T newValue = value;
    bool hasReplace = false;
    for (final validator in validators) {
      final invalidReason = validator(value);
      if (invalidReason is ReasonValidation<T>) {
        return invalidReason;
      } else if (invalidReason is ReplaceValidation<T>) {
        newValue = invalidReason.value;
        hasReplace = true;
      }
    }
    if (hasReplace) {
      return ReplaceValidation(newValue);
    }
    return null;
  };
}

class StringField extends FormItem<String> {
  final Widget label;
  final bool inline, multiline;
  final I18nString? placeholder;
  StringField(this.label, super.value, {this.inline = false, this.placeholder, this.multiline = false});

  @override
  Widget createWidget(FormData form) {
    return StringFieldWidget(
      field: this,
      form: form,
    );
  }
}

class StringFieldWidget extends StatefulWidget {
  final FormData form;
  final StringField field;

  const StringFieldWidget({Key? key, required this.form, required this.field}) : super(key: key);

  @override
  _StringFieldWidgetState createState() => _StringFieldWidgetState();
}

class _StringFieldWidgetState extends State<StringFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value.value);
    widget.form.addListener(_update);
  }

  void _update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant StringFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.value.value != widget.field.value.value) {
      _controller.text = widget.field.value.value;
    }
    if (oldWidget.field != widget.field) {
      oldWidget.form.removeListener(_update);
      widget.form.addListener(_update);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.form.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardFieldWidget(
      label: widget.field.label,
      invalidReason: widget.field.value.invalidReason?.call(i18n),
      childPosition: widget.field.inline && !widget.field.multiline ? ChildPosition.beside : ChildPosition.under,
      child: TextField(
        controller: _controller,
        maxLines: widget.field.multiline ? 5 : 1,
        keyboardType: widget.field.multiline ? TextInputType.multiline : TextInputType.text,
        decoration: InputDecoration(
          hintText: widget.field.placeholder?.call(i18n),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: CompactData.of(context).theme.hoveredSurfaceColor,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: CompactData.of(context).theme.focusedSurfaceColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          var validate = widget.field._validate(value);
          if (validate is ReplaceValidation<String>) {
            _controller.text = validate.value;
            _controller.selection = TextSelection.fromPosition(TextPosition(offset: validate.value.length));
            widget.field.value = widget.field.value.copyWithValueAndReason(validate.value, null);
          } else if (validate is ReasonValidation<String>) {
            widget.field.value = widget.field.value.copyWithValueAndReason(value, validate.reason);
          } else {
            widget.field.value = widget.field.value.copyWithValueAndReason(value, null);
          }
          if (widget.field.value.invalidReason != null) {
            widget.form.value = widget.form.value.copyWith(widget.field);
          } else {
            widget.form.value = widget.form.value.copyWithout(widget.field);
          }
        },
      ),
    );
  }
}

class BooleanField extends FormItem<bool> {
  final Widget label;
  BooleanField(this.label, super.value);

  @override
  Widget createWidget(FormData form) {
    return BooleanFieldWidget(
      field: this,
      form: form,
    );
  }
}

class BooleanFieldWidget extends StatefulWidget {
  final FormData form;
  final BooleanField field;

  const BooleanFieldWidget({Key? key, required this.form, required this.field}) : super(key: key);

  @override
  _BooleanFieldWidgetState createState() => _BooleanFieldWidgetState();
}

class _BooleanFieldWidgetState extends State<BooleanFieldWidget> {
  void _update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.form.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant BooleanFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field != widget.field) {
      oldWidget.form.removeListener(_update);
      widget.form.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.form.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardFieldWidget(
      label: widget.field.label,
      invalidReason: widget.field.value.invalidReason?.call(i18n),
      childPosition: ChildPosition.beside,
      child: Align(
        alignment: Alignment.centerRight,
        child: Checkbox(
          value: widget.field.value.value,
          onChanged: (value) {
            var validate = widget.field._validate(value ?? false);
            if (validate is ReplaceValidation<bool>) {
              widget.field.value = widget.field.value.copyWithValueAndReason(validate.value, null);
            } else if (validate is ReasonValidation<bool>) {
              widget.field.value = widget.field.value.copyWithValueAndReason(value ?? false, validate.reason);
            } else {
              widget.field.value = widget.field.value.copyWithValueAndReason(value ?? false, null);
            }
            if (widget.field.value.invalidReason != null) {
              widget.form.value = widget.form.value.copyWith(widget.field);
            } else {
              widget.form.value = widget.form.value.copyWithout(widget.field);
            }
          },
        ),
      ),
    );
  }
}

class Option<T> {
  final I18nString label;
  final Widget? icon;
  final T value;
  Option(this.label, this.value, {this.icon});
}

class SelectField<T> extends FormItem<List<int>> {
  final Widget label;
  final List<Option<T>> options;
  final int maxSelection; // if more than 1, then use checkboxes, otherwise use dropdown/radios
  final bool showAllOptions; // if true, then show as checkboxes/radios, otherwise show as dropdown, this is ignored if maxSelection more than 1
  final bool inline; // ignored if showAllOptions is true or maxSelection more than 1
  SelectField(this.label, this.options, super.value, {this.maxSelection = 1, this.showAllOptions = false, this.inline = false});

  @override
  Widget createWidget(FormData form) {
    return SelectFieldWidget(
      field: this,
      form: form,
    );
  }
}

class SelectFieldWidget<T> extends StatefulWidget {
  final FormData form;
  final SelectField<T> field;

  const SelectFieldWidget({Key? key, required this.form, required this.field}) : super(key: key);

  @override
  _SelectFieldWidgetState<T> createState() => _SelectFieldWidgetState<T>();
}

class _SelectFieldWidgetState<T> extends State<SelectFieldWidget<T>> {
  void _update() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.form.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant SelectFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field != widget.field) {
      oldWidget.form.removeListener(_update);
      widget.form.addListener(_update);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.form.removeListener(_update);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.field.maxSelection > 1) {
      child = Column(
        children: widget.field.options.mapIndexed((index, option) {
          return CheckboxListTile(
            value: widget.field.value.value.contains(index),
            secondary: option.icon,
            onChanged: widget.field.value.value.contains(index) || widget.field.value.value.length < widget.field.maxSelection
                ? (value) {
                    if (value ?? false) {
                      List<int> old = widget.field.value.value;
                      if (old.length + 1 > widget.field.maxSelection) {
                        return;
                      }
                      var newValue = [...old, index];
                      var validate = widget.field._validate(newValue);
                      if (validate is ReplaceValidation<List<int>>) {
                        widget.field.value = FormValue(validate.value, null);
                      } else if (validate is ReasonValidation<List<int>>) {
                        widget.field.value = FormValue(newValue, validate.reason);
                      } else {
                        widget.field.value = FormValue(newValue, null);
                      }
                      if (widget.field.value.invalidReason != null) {
                        widget.form.value = widget.form.value.copyWith(widget.field);
                      } else {
                        widget.form.value = widget.form.value.copyWithout(widget.field);
                      }
                    } else {
                      List<int> old = widget.field.value.value;
                      var newValue = old.where((element) => element != index).toList();
                      var validate = widget.field._validate(newValue);
                      if (validate is ReplaceValidation<List<int>>) {
                        widget.field.value = FormValue(validate.value, null);
                      } else if (validate is ReasonValidation<List<int>>) {
                        widget.field.value = FormValue(newValue, validate.reason);
                      } else {
                        widget.field.value = FormValue(newValue, null);
                      }
                      if (widget.field.value.invalidReason != null) {
                        widget.form.value = widget.form.value.copyWith(widget.field);
                      } else {
                        widget.form.value = widget.form.value.copyWithout(widget.field);
                      }
                    }
                  }
                : null,
            title: option.label(i18n).asTextWidget(),
            dense: true,
          );
        }).toList(),
      );
    } else {
      if (widget.field.showAllOptions) {
        child = Column(
          children: widget.field.options.mapIndexed((index, option) {
            return RadioListTile<int>(
              value: index,
              selected: widget.field.value.value.contains(index),
              secondary: option.icon,
              onChanged: (value) {
                if (value != null) {
                  var newValue = [value];
                  var validate = widget.field._validate(newValue);
                  if (validate is ReplaceValidation<List<int>>) {
                    widget.field.value = FormValue(validate.value, null);
                  } else if (validate is ReasonValidation<List<int>>) {
                    widget.field.value = FormValue(newValue, validate.reason);
                  } else {
                    widget.field.value = FormValue(newValue, null);
                  }
                  if (widget.field.value.invalidReason != null) {
                    widget.form.value = widget.form.value.copyWith(widget.field);
                  } else {
                    widget.form.value = widget.form.value.copyWithout(widget.field);
                  }
                }
              },
              title: option.label(i18n).asTextWidget(),
              dense: true,
              groupValue: widget.field.value.value.firstOrNull,
            );
          }).toList(),
        );
      } else {
        child = DropdownButtonFormField<int>(
          dropdownColor: app.hoveredTreeColor,
          borderRadius: BorderRadius.circular(4),
          decoration: InputDecoration(
            prefixIcon: widget.field.options.isEmpty ? null : widget.field.options[widget.field.value.value.firstOrNull ?? 0].icon,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: CompactData.of(context).theme.hoveredSurfaceColor,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: CompactData.of(context).theme.focusedSurfaceColor,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.only(
              left: 12,
              right: 8,
            ),
          ),
          value: widget.field.value.value.firstOrNull ?? 0,
          onChanged: (value) {
            if (value != null) {
              var newValue = [value];
              var validate = widget.field._validate(newValue);
              if (validate is ReplaceValidation<List<int>>) {
                widget.field.value = FormValue(validate.value, null);
              } else if (validate is ReasonValidation<List<int>>) {
                widget.field.value = FormValue(newValue, validate.reason);
              } else {
                widget.field.value = FormValue(newValue, null);
              }
              if (widget.field.value.invalidReason != null) {
                widget.form.value = widget.form.value.copyWith(widget.field);
              } else {
                widget.form.value = widget.form.value.copyWithout(widget.field);
              }
            }
          },
          items: widget.field.options.mapIndexed((index, option) {
            return DropdownMenuItem<int>(
              value: index,
              child: option.label(i18n).asTextWidget(),
            );
          }).toList(),
        );
      }
    }
    return StandardFieldWidget(
      label: widget.field.label,
      invalidReason: widget.field.value.invalidReason?.call(i18n),
      childPosition: widget.field.inline && !widget.field.showAllOptions && widget.field.maxSelection <= 1 ? ChildPosition.beside : ChildPosition.under,
      child: child,
    );
  }
}
