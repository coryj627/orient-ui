// Accessibility audit of every widget page of the example app (flutter_a11y_test,
// layer "runtime"), on this fork only: dogfood of https://github.com/coryj627/flutter-a11y.
//
// Each page is pumped the way the example's main.dart pumps it: inside the Style
// inherited widget and a MaterialApp with the same light theme. Findings are RECORDED,
// not asserted: the RuntimeFindingsSink in test/flutter_test_config.dart writes them to
// .a11y/flutter/runtime-findings.json and `a11y_check_flutter scan` (run at the
// repository root, so the templates' code is attributed) decides, against the committed
// baseline, what fails CI.
import 'dart:async';

import 'package:example/pages/alert_popup_page.dart';
import 'package:example/pages/button_page.dart';
import 'package:example/pages/card_box_page.dart';
import 'package:example/pages/colors_page.dart';
import 'package:example/pages/confirmation_popup_page.dart';
import 'package:example/pages/copy_button_page.dart';
import 'package:example/pages/docs_page.dart';
import 'package:example/pages/empty_state_page.dart';
import 'package:example/pages/info_banner_page.dart';
import 'package:example/pages/multi_choice_page.dart';
import 'package:example/pages/multi_choice_tile_page.dart';
import 'package:example/pages/nav_bar_page.dart';
import 'package:example/pages/picker_page.dart';
import 'package:example/pages/popover_menu_page.dart';
import 'package:example/pages/popup_page.dart';
import 'package:example/pages/search_field_page.dart';
import 'package:example/pages/single_choice_page.dart';
import 'package:example/pages/single_choice_tile_page.dart';
import 'package:example/pages/spinner_page.dart';
import 'package:example/pages/tabs_page.dart';
import 'package:example/pages/tag_page.dart';
import 'package:example/pages/tappable_icon_page.dart';
import 'package:example/pages/tile_page.dart';
import 'package:example/pages/toast_page.dart';
import 'package:example/pages/toggle_page.dart';
import 'package:example/pages/toggle_tile_page.dart';
import 'package:example/pages/typography_page.dart';
import 'package:example/pages/widgets_page.dart';
import 'package:example/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_a11y_test/flutter_a11y_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _audit(WidgetTester tester, String screenId, Widget page) async {
  // google_fonts rethrows asynchronously when a font is neither bundled nor
  // fetchable; drop exactly those errors, hand anything else to the test.
  final done = Completer<void>();
  runZonedGuarded(
    () => _pumpAndAudit(
      tester,
      screenId,
      page,
    ).then(done.complete, onError: done.completeError),
    (error, stack) {
      if ('$error'.contains('GoogleFonts') ||
          '$error'.contains('google_fonts')) {
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    },
  );
  await done.future;
}

/// Clears the exceptions this harness expects and fails on anything else: a demo page
/// that overflows the phone-sized screen on its first frame (the audit's reflow passes
/// measure every RenderFlex themselves), and a listener that rebuilds a disposed element
/// while the app is taken down.
void _dropKnown(WidgetTester tester) {
  final e = tester.takeException();
  if (e == null) return;
  final text = e.toString();
  // "Multiple exceptions" is Flutter's aggregate when one pump throws several;
  // on these pages that is the same Row overflowing at two widths (segment bar).
  if (text.contains('A RenderFlex overflowed') ||
      text.contains('_ElementLifecycle.defunct') ||
      text.startsWith('Multiple exceptions')) {
    return;
  }
  fail('Unexpected exception during the audit: $e');
}

Future<void> _pumpAndAudit(
  WidgetTester tester,
  String screenId,
  Widget page,
) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(const Size(390, 844));
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Style(
      brightness: Brightness.light,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: page,
      ),
    ),
  );
  // No settle pumps: auditScreen settles whatever the first frame started.
  _dropKnown(tester);
  final result = await auditScreen(tester, screenId: screenId);
  // ignore: avoid_print
  print('a11y $screenId: ${result.findings.length} finding(s)');
  _dropKnown(tester);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  _dropKnown(tester);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final pages = <String, Widget>{
    'widgets': const WidgetsPage(),
    'docs': const DocsPage(),
    'colors': const ColorsPage(),
    'typography': const TypographyPage(),
    'button': const ButtonPage(),
    'copy-button': const CopyButtonPage(),
    'tappable-icon': const TappableIconPage(),
    'toggle': const TogglePage(),
    'toggle-tile': const ToggleTilePage(),
    'tile': const TilePage(),
    'tag': const TagPage(),
    'tabs': const TabsPage(),
    'nav-bar': const NavBarPage(),
    'card-box': const CardBoxPage(),
    'empty-state': const EmptyStatePage(),
    'info-banner': const InfoBannerPage(),
    'spinner': const SpinnerPage(),
    'search-field': const SearchFieldPage(),
    'picker': const PickerPage(),
    'single-choice': const SingleChoicePage(),
    'single-choice-tile': const SingleChoiceTilePage(),
    'multi-choice': const MultiChoicePage(),
    'multi-choice-tile': const MultiChoiceTilePage(),
    'popup': const PopupPage(),
    'alert-popup': const AlertPopupPage(),
    'confirmation-popup': const ConfirmationPopupPage(),
    'popover-menu': const PopoverMenuPage(),
    'toast': const ToastPage(),
  };
  for (final entry in pages.entries) {
    testWidgets(entry.key, (tester) async {
      await _audit(tester, entry.key, entry.value);
    });
  }
}
