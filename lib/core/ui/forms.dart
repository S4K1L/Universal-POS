import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/lang.dart';
import '../money/money.dart';
import '../theme/tokens.dart';

/// Small building blocks shared by the form panels.
class FormGap extends StatelessWidget {
  const FormGap([this.h = 14, Key? key]) : super(key: key);
  final double h;
  @override
  Widget build(BuildContext context) => SizedBox(height: h);
}

class FormHeading extends StatelessWidget {
  const FormHeading(this.text, {super.key, this.hint});
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(text).toUpperCase(), style: Theme.of(context).textTheme.labelSmall!.copyWith(letterSpacing: 0.8)),
          if (hint != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr(hint!), style: Theme.of(context).textTheme.bodySmall)),
        ]),
      );
}

class MoneyField extends StatelessWidget {
  const MoneyField({super.key, required this.controller, required this.label, this.symbol = '৳', this.helper, this.enabled = true, this.onChanged, this.decimals = 2, this.autofocus = false});
  final TextEditingController controller;
  final String label;
  final String symbol;
  final String? helper;
  final bool enabled, autofocus;
  final ValueChanged<String>? onChanged;
  final int decimals;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,' '$decimals' r'}'))],
        decoration: InputDecoration(labelText: context.tr(label), prefixText: '$symbol ', helperText: helper == null ? null : context.tr(helper!)),
      );
}

int paisaOf(TextEditingController c) => c.text.trim().isEmpty ? 0 : parsePaisa(c.text.trim());

class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.title, this.subtitle, required this.value, required this.onChanged, this.enabled = true});
  final String title;
  final String? subtitle;
  final bool value, enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(R.control), border: Border.all(color: t.outline)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(title), style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) Text(context.tr(subtitle!), style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        Switch(value: value, onChanged: enabled ? onChanged : null),
      ]),
    );
  }
}

class DropdownBox<T> extends StatelessWidget {
  const DropdownBox({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.icon});
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        borderRadius: BorderRadius.circular(R.control),
        decoration: InputDecoration(labelText: context.tr(label), prefixIcon: icon == null ? null : Icon(icon, size: 19)),
      );
}

/// Date picker that looks like a field.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged, this.first, this.last, this.clearable = true});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? first, last;
  final bool clearable;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(R.control),
        onTap: () async {
          final now = DateTime.now();
          final d = await showDatePicker(context: context, initialDate: value ?? now, firstDate: first ?? DateTime(now.year - 2), lastDate: last ?? DateTime(now.year + 8));
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: context.tr(label), prefixIcon: const Icon(Icons.event_rounded, size: 19), suffixIcon: clearable && value != null ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => onChanged(null)) : null),
          child: Text(value == null ? '—' : context.fmt.date(value!), style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
}
