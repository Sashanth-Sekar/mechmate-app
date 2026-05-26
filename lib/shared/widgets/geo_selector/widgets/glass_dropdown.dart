import 'package:flutter/material.dart';

class GlassDropdown<T> extends StatelessWidget {
  final bool enabled;
  final String label;

  final T? value;
  final String displayText;

  final List<T> items;
  final String Function(T item) itemToString;
  final void Function(T? selected) onChanged;

  final bool loading;
  final String? errorText;
  final String? emptyText;

  final String searchText;
  final void Function(String value) onSearchChanged;

  final bool showGoldSelection;
  final Border? goldBorder;

  final TextStyle? textStyle;

  const GlassDropdown({
    super.key,
    required this.enabled,
    required this.label,
    required this.value,
    required this.displayText,
    required this.items,
    required this.itemToString,
    required this.onChanged,
    required this.loading,
    required this.errorText,
    required this.searchText,
    required this.onSearchChanged,
    this.emptyText,
    this.showGoldSelection = false,
    this.goldBorder,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = goldBorder ??
        Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.08),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelRow(label: label, enabled: enabled),
          const SizedBox(height: 10),

          if (!enabled)
            _DisabledDisplay(text: displayText, label: label)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchField(
                  value: searchText,
                  onChanged: onSearchChanged,
                  enabled: enabled,
                ),
                const SizedBox(height: 10),

                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (errorText != null)
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  DropdownButtonFormField<T>(
                    isExpanded: true,
                    initialValue: value,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    dropdownColor: isDark ? const Color(0xFF121212) : Colors.white,
                    items: items
                        .map(
                          (e) => DropdownMenuItem<T>(
                            value: e,
                            child: Text(
                              itemToString(e),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: enabled ? onChanged : null,
                    hint: Text(
                      displayText.isEmpty ? 'Choose $label' : displayText,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    style: textStyle ??
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                  ),

                if (!loading && items.isEmpty && emptyText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      emptyText!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final bool enabled;

  const _LabelRow({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 14,
          color: enabled ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white60 : Colors.black45),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: enabled
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ],
    );
  }
}

class _DisabledDisplay extends StatelessWidget {
  final String text;
  final String label;

  const _DisabledDisplay({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      child: Text(
        text.isEmpty ? 'Select $label first' : text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// A search field that persists its [TextEditingController] across rebuilds,
/// preventing cursor reset on every keystroke.
class _SearchField extends StatefulWidget {
  final String value;
  final void Function(String) onChanged;
  final bool enabled;

  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync only when externally cleared (e.g. parent resets search on state/city change)
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      enabled: widget.enabled,
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search_rounded,
            size: 18, color: isDark ? Colors.white60 : Colors.black45),
        hintText: 'Search',
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black45,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }
}
