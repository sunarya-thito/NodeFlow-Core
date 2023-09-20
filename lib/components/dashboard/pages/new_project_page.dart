import 'package:flutter/widgets.dart';
import 'package:nodeflow/components/form/form.dart';
import 'package:nodeflow/components/form/wizard.dart';
import 'package:nodeflow/components/locale_widget.dart';
import 'package:nodeflow/components/page_holder.dart';
import 'package:nodeflow/theme/compact_data.dart';

class NewProjectPage extends StatefulWidget {
  const NewProjectPage({Key? key}) : super(key: key);

  @override
  _NewProjectPageState createState() => _NewProjectPageState();
}

class TempAppModule {
  final String name;

  const TempAppModule(this.name);
}

class _NewProjectPageState extends State<NewProjectPage> {
  late FormItem<String> projectName;
  late FormItem<String> projectDescription;
  late FormItem<List<int>> selectModule;
  late FormData formData, selectModuleFormData;

  @override
  void initState() {
    super.initState();
    projectName = StringField(TextBuilder((i18n) => i18n.projectCreateName), '', placeholder: (i18n) => i18n.projectCreateNamePlaceholder)
        .validate(validateMaxLength(32).combine(validateNotEmpty()));
    projectDescription =
        StringField(TextBuilder((i18n) => i18n.projectCreateDescription), '', multiline: true, placeholder: (i18n) => i18n.projectCreateDescriptionPlaceholder)
            .validate(validateMaxLength(256));
    selectModule = SelectField(
      TextBuilder((i18n) => i18n.projectCreateSelectModule),
      [
        Option((i18n) => 'SpigotMC Plugin', const TempAppModule('Vault Plugin Module')),
        Option((i18n) => 'Paper Plugin', const TempAppModule('Vault Plugin Module')),
      ],
      [0],
      showAllOptions: true,
    );
    formData = FormData([
      projectName,
      projectDescription,
    ]);
    selectModuleFormData = FormData([
      selectModule,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Wizard(
      home: WizardPage(
        title: i18n.projectCreate.asTextWidget(),
        form: formData,
        next: (form) {
          return NextPageAction(
              WizardPage(
                title: i18n.projectCreate.asTextWidget(),
                form: selectModuleFormData,
                next: (form) {
                  return FinishAction(enabled: form.isValid);
                },
              ),
              enabled: form.isValid);
        },
      ),
      finishButtonLabel: i18n.projectCreateButton.asTextWidget(),
      onCancel: () {
        SubNavigator.of(context).goBack();
      },
    );
  }
}
