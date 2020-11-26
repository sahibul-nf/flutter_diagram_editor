import 'package:flutter/material.dart';

import 'model/component_options_data.dart';

class ComponentOption extends StatelessWidget {
  final int componentId;
  final double optionSize;
  final ComponentOptionData option;
  final tooltip;

  const ComponentOption({
    Key key,
    @required this.componentId,
    @required this.optionSize,
    @required this.option,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: option.color,
        shape: BoxShape.circle,
      ),
      width: optionSize,
      height: optionSize,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(option.icon),
        onPressed: () {
          if (option.onOptionTap != null) {
            option.onOptionTap(componentId);
          }
        },
      ),
    );
  }
}