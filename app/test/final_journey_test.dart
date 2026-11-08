import 'dart:typed_data';
import 'package:carebridge/visit_sheet_page.dart';
import 'package:carebridge/api.dart';
import 'package:carebridge/main.dart';
import 'package:carebridge/hospitals.dart';
import 'package:carebridge/clinic_reviews.dart';
import 'package:carebridge/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'visit_focus_test.dart' show VisitApi;

class AutoApi extends VisitApi {
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (path == '/api/cards') return method == 'POST' ? card : [];
    if (path.endsWith('/translate')) {
      translations++;
      return VisitApi(draft: true).card;
    }
    return super.request(path, method: method, body: body);
  }
}

class EyesApi extends Api {
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async => {
    'hospitals': [
      {
        'id': 'eye',
        'name': 'Eye clinic fixture',
        'address': 'Pohang',
        'phone': '',
        'type': '의원',
        'departments': [
          {'name': '안과', 'specialists': 1},
        ],
      },
      {
        'id': 'dental',
        'name': 'Dental fixture',
        'address': 'Pohang',
        'phone': '',
        'type': '의원',
        'departments': [
          {'name': '치과', 'specialists': 1},
          {'name': '안과', 'specialists': 0},
        ],
      },
    ],
  };
}

class NoPublishApi extends Api {
  int calls = 0;
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    calls++;
    return [];
  }
}

class ReviewApi extends Api {
  Map? published;
  @override
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
  }) async {
    if (method == 'POST') {
      published = body as Map;
      return {};
    }
    return [];
  }
}

void main() {
  setUp(() {
    MoriLanguage.current.value = 'en';
    MoriLanguage.catalog = {};
  });
  testWidgets(
    'completion requests consent automatically then translates once',
    (tester) async {
      final api = AutoApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitCards(api: api, ko: false, aiReady: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '1. What is bothering you most?'),
        'Fictional sore throat',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '2. When did it begin?'),
        'Yesterday',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final consent = find.byType(CheckboxListTile);
      await tester.ensureVisible(consent);
      await tester.pumpAndSettle();
      await tester.tap(consent);
      await tester.pump();
      final finish = find.text('Finish and prepare my visit sheet');
      await tester.ensureVisible(finish);
      await tester.pumpAndSettle();
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(find.text('Send this card for translation?'), findsOneWidget);
      expect(api.translations, 0);
      await tester.tap(find.text('Agree and translate'));
      await tester.pumpAndSettle();
      expect(api.translations, 1);
      expect(find.text('Translate with AI'), findsNothing);
      expect(find.text('Save my visit sheet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('eyes filters to ophthalmology and reveals results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Hospitals(api: EyesApi(), ko: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final eyes = find.text('Eyes');
    await tester.ensureVisible(eyes);
    await tester.tap(eyes);
    await tester.pumpAndSettle();
    expect(find.text('Eye clinic fixture'), findsOneWidget);
    expect(find.text('Dental fixture'), findsNothing);
    expect(
      find.textContaining('results · nearest').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'demo examples stay clearly fictional and make no guest API calls',
    (tester) async {
      final api = NoPublishApi();
      await tester.pumpWidget(
        MaterialApp(
          home: ClinicReviewsPage(
            api: api,
            hospital: {'id': demoClinicId, 'name': '양덕이비인후과의원'},
            canReview: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('DEMO ONLY · Fictional reviews, not patient feedback'),
        findsOneWidget,
      );
      expect(find.text('Publish'), findsNothing);
      expect(api.calls, 0);
    },
  );
  testWidgets(
    'sheet home and after-visit actions work independently of PDF export',
    (tester) async {
      bool home = false, review = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VisitSheetPage(
                    card: VisitApi(draft: true).card,
                    bytes: Uint8List(0),
                    onHome: () => home = true,
                    onReview: () => review = true,
                  ),
                ),
              ),
              child: const Text('Open fixture'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open fixture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finished your visit? Leave an experience'));
      expect(review, isTrue);
      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(home, isTrue);
      expect(find.text('Open fixture'), findsOneWidget);
    },
  );
  testWidgets(
    'real review requires consent and preserves the selected hospital',
    (tester) async {
      final api = ReviewApi();
      await tester.pumpWidget(
        MaterialApp(
          home: ClinicReviewsPage(
            api: api,
            hospital: {'id': 'other', 'name': 'Fixture clinic'},
            canReview: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Example: The doctor was kind.'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Publish'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Process, communication and tips'),
        'Fictional QA experience only.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Publish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish'));
      await tester.pumpAndSettle();
      expect(api.published?['place'], 'Fixture clinic');
      expect(api.published?['consent'], true);
      expect(api.published?['body'], 'Fictional QA experience only.');
    },
  );
}
