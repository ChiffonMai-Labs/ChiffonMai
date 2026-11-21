import 'package:flutter/cupertino.dart';

/// iOS 搜索入口。浮层模式把整行作为按钮，只在浮层里的输入框获取焦点。
class AppleSearchField extends StatelessWidget {
  const AppleSearchField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.onOpen,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FocusNode? focusNode;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (onOpen == null) {
      return CupertinoSearchTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onSuffixTap: onClear,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(9),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Row(children: [
          Expanded(
              child: CupertinoButton(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: onOpen,
            child: Row(children: [
              const Icon(CupertinoIcons.search,
                  size: 20, color: CupertinoColors.secondaryLabel),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(
                value.text.isEmpty ? placeholder : value.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: (value.text.isEmpty
                            ? CupertinoColors.secondaryLabel
                            : CupertinoColors.label)
                        .resolveFrom(context)),
              )),
            ]),
          )),
          if (value.text.isNotEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onClear,
              child: Icon(CupertinoIcons.xmark_circle_fill,
                  size: 20,
                  semanticLabel:
                      CupertinoLocalizations.of(context).clearButtonLabel,
                  color: CupertinoColors.secondaryLabel),
            ),
        ]),
      ),
    );
  }
}
