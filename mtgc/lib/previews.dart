import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'models/booster_product.dart';
import 'pages/booster.dart';
import 'pages/collection.dart';
import 'pages/menu.dart';
import 'theme.dart';

PreviewThemeData previewTheme() => PreviewThemeData(
  materialLight: buildAppTheme(),
  materialDark: buildAppTheme(),
);

@Preview(name: 'Menu', theme: previewTheme)
Widget menuPreview() => const Menu();

@Preview(name: 'Booster', theme: previewTheme)
Widget boosterPreview() => Booster(product: boosterCatalog.first);

@Preview(name: 'Collection', theme: previewTheme)
Widget collectionPreview() => const Collection();
