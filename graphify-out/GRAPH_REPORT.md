# Graph Report - my_auto_guide  (2026-08-15)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 2415 nodes · 3991 edges · 148 communities (138 shown, 10 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 31 edges (avg confidence: 0.69)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d10f5034`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- inicio_app.dart
- lib/render-report.mjs
- dedup-recs.mjs
- sanitizers/index.mjs
- workspace-resolver.mjs
- rutas_screen.dart
- verifyClaim
- notification_service.dart
- ai_chat_screen.dart
- vehicle_registration_view.dart
- vercel.mjs
- parametrizacion_mantenimientos.dart
- login_screen.dart
- package:flutter_test/flutter_test.dart
- extract-claims.mjs
- captura_360_screen.dart
- weekly_insight_card.dart
- gates/index.mjs
- historial_rutas_screen.dart
- guia.dart
- support-topics.mjs
- gastos_screen.dart
- report_service.dart
- SimpleEntry
- my_application.cc
- lib/reconcile-candidates.mjs
- navigation_widgets.dart
- StatelessWidget
- auth_provider.dart
- sync_service.dart
- navigation_controller.dart
- dashboard_widgets.dart
- investigation-brief.mjs
- scanners/index.mjs
- background_nav_service.dart
- database.dart
- collect-signals.mjs
- liquid_glass_fab.dart
- citations.mjs
- GeneratedPluginRegistrant.swift
- navigation_telemetry.dart
- supabase_service.dart
- registro_screen.dart
- scripts/deep-dive.mjs
- simit_webview.dart
- bitacora_tanqueo_screen.dart
- runt_webview.dart
- route-normalize.mjs
- Color
- app_localizations.dart
- State
- win32_window.cpp
- collect-sub-agent-outputs.mjs
- merge-signals.mjs
- main.dart
- List
- navigation_service.dart
- prepare-investigation-brief.mjs
- throttle.mjs
- VehicleStatusWidgetProvider.java
- package:supabase_flutter/supabase_flutter.dart
- vehicle_expenses_logic.dart
- auth_service.dart
- _
- FlutterWindow
- verify-and-regen.mjs
- verifyNextCacheComponentsRouteChainFile
- readClaimFile
- email_service.dart
- verifyNextCacheLifetimeFreshnessSupported
- ai_bot_service.dart
- fuel_log_model.dart
- vehicle_catalog_service.dart
- vehicle_storage_service.dart
- MaterialPageRoute
- Win32Window
- vehicle_ai_logic.dart
- maintenance_config_service.dart
- grade-recommendation.mjs
- app_localizations_en.dart
- telemetry_calculator.dart
- wWinMain
- gate-investigations.mjs
- withRouteShapeWarnings
- brand_theme.dart
- manifest.json
- hard-gates.mjs
- uncached-route.mjs
- Semaphore
- vehicle_health_logic.dart
- MessageHandler
- scanner-driven.mjs
- select-candidates.mjs
- .application
- performance_guard.dart
- contract.mjs
- rendering-mode-mislabel.mjs
- large-static-asset.mjs
- docs-library.json
- maintenance_prediction.dart
- package:flutter/material.dart
- framework-support.mjs
- cwv-poor.mjs
- cache-components-suspense-dedupe.mjs
- edge-heavy-import.mjs
- turbo-force-bypass.mjs
- use-cache-date-stamp.mjs
- vehicle_performance_logic.dart
- deploy.sh
- deploy-codex.sh
- unoptimized-image.mjs
- FlutterMacOS
- AppDelegate
- RegisterGeneratedPlugins
- AppLocalizations
- external-api-slow.mjs
- platform-bot-protection.mjs
- platform-fluid-compute.mjs
- usage-spike-triage.mjs
- verify-claim.mjs
- MainActivity.kt
- RunnerTests
- calendar_sync_service.dart
- build-minutes-fanout.mjs
- isr-overrevalidation.mjs
- middleware-heavy.mjs
- middleware-broad-matcher.mjs
- missing-cache-headers.mjs
- Exception
- RegisterPlugins
- sveltekit-prerender-missing.mjs
- VehicleKind
- VehicleRegistrationView
- double?
- String?
- Widget
- dart:io
- biometric_service.dart
- app_widget_logic.dart
- vehicle_provider.dart
- ChangeNotifier
- _RutasScreenState

## God Nodes (most connected - your core abstractions)
1. `verifyClaim()` - 42 edges
2. `renderReport()` - 33 edges
3. `extractClaims()` - 31 edges
4. `canonicalizeRoute()` - 27 edges
5. `recText()` - 24 edges
6. `main()` - 24 edges
7. `recText()` - 23 edges
8. `Win32Window` - 22 edges
9. `lineOf()` - 19 edges
10. `_` - 19 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h
- `MessageHandler` --references--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (148 total, 10 thin omitted)

### Community 0 - "inicio_app.dart"
Cohesion: 0.02
Nodes (93): Agregar_carro.dart, Agregar_vehiculo.dart, ../../ai_bot/presentation/ai_chat_screen.dart, ../../auth/login_screen.dart, captura_360_screen.dart, ../../../core/services/calendar_sync_service.dart, ../../../core/services/vehicle_pdf_report_service.dart, ../../expenses/presentation/bitacora_tanqueo_screen.dart (+85 more)

### Community 1 - "lib/render-report.mjs"
Cohesion: 0.05
Nodes (85): buildBudgetSummary(), buildChatPreview(), buildExactChatMessage(), buildOptions(), buildPrintCheck(), buildQuestionPayload(), buildQuestionText(), renderBudgetSummaryMarkdown() (+77 more)

### Community 2 - "dedup-recs.mjs"
Cohesion: 0.08
Nodes (57): affectedFiles(), appliesAlsoEntry(), cacheLifeIntent(), dedupEditTarget(), dedupeRecommendations(), dedupIntent(), firstAffectedFile(), fixShape() (+49 more)

### Community 3 - "sanitizers/index.mjs"
Cohesion: 0.05
Nodes (43): computeImpactLabel(), cwvIssue(), formatCwvIssue(), formatInteger(), joinEnglish(), parseSigNumber(), round1(), round2() (+35 more)

### Community 4 - "workspace-resolver.mjs"
Cohesion: 0.08
Nodes (54): buildPackageLookup(), buildResolver(), DEFAULT_RESOLVE_OPTIONS, detectMonorepoRoot(), escapeRegExp(), expandParts(), expandResolvedSpecifier(), expandPureBarrel() (+46 more)

### Community 5 - "rutas_screen.dart"
Cohesion: 0.05
Nodes (38): ../../../core/services/navigation_service.dart, _animCtrl, build, _buildBottomPanel, _buildMap, _buscarDestino, _cargarInfoVehiculo, _controller (+30 more)

### Community 6 - "verifyClaim"
Cohesion: 0.18
Nodes (19): recText(), verifyAuthGuardParallelizationSafety(), verifyCache404LongTtlSafety(), verifyCachePolicyPositiveOrNoReadyRec(), verifyCacheVaryCardinalitySafe(), verifyClaim(), verifyImmutableDynamicRouteSafety(), verifyNextCacheComponentsRouteSegmentConfig() (+11 more)

### Community 7 - "notification_service.dart"
Cohesion: 0.12
Nodes (15): FlutterLocalNotificationsPlugin, cancelAll, ensureExactAlarmsEnabled, init, _instance, NotificationService, _notificationsPlugin, _platformChannel (+7 more)

### Community 8 - "ai_chat_screen.dart"
Cohesion: 0.06
Nodes (35): ../../core/services/ai_bot_service.dart, FocusNode, AIChatScreen, _AIChatScreenState, build, _buildInputArea, _ChatBubble, createState (+27 more)

### Community 9 - "vehicle_registration_view.dart"
Cohesion: 0.05
Nodes (36): ../../../../core/services/vehicle_catalog_service.dart, ../inicio_app.dart, _apodoController, brandColors, build, _buildField, _cambiarMarca, catalogo (+28 more)

### Community 10 - "vercel.mjs"
Cohesion: 0.12
Nodes (35): isDailyQuotaExceeded(), baselineStack(), categorizeError(), checkAuth(), checkCliVersion(), checkObservabilityPlusConfiguration(), classifyObservabilityPlusConfiguration(), detectNextCacheComponents() (+27 more)

### Community 11 - "parametrizacion_mantenimientos.dart"
Cohesion: 0.06
Nodes (35): class, ../../../core/services/ocr_service.dart, _aceite, build, _buildKmInput, _buildMaintenanceCard, _cadena, createState (+27 more)

### Community 12 - "login_screen.dart"
Cohesion: 0.06
Nodes (33): ../../core/services/auth_service.dart, ../../core/services/biometric_service.dart, _auth, _biometric, _bootstrapSession, canUseBiometrics, CarRentalLoginScreen, _CarRentalLoginScreenState (+25 more)

### Community 13 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (23): package:flutter_test/flutter_test.dart, package:my_auto_guide/core/logic/fuel_efficiency_logic.dart, package:my_auto_guide/core/logic/vehicle_ai_logic.dart, package:my_auto_guide/core/logic/vehicle_expenses_logic.dart, package:my_auto_guide/core/logic/vehicle_health_logic.dart, package:my_auto_guide/core/logic/vehicle_performance_logic.dart, package:my_auto_guide/features/expenses/domain/models/fuel_log_model.dart, package:my_auto_guide/features/navigation/logic/telemetry_calculator.dart (+15 more)

### Community 14 - "extract-claims.mjs"
Cohesion: 0.18
Nodes (31): asArray(), cacheRecommendationFiles(), extractClaims(), isCacheCandidate(), mentionsAuthSensitiveParallelization(), mentionsCachedNotFoundOr404(), mentionsCacheLifeCdnHeaderClaim(), mentionsCacheLifetimeChange() (+23 more)

### Community 15 - "captura_360_screen.dart"
Cohesion: 0.06
Nodes (31): CameraController?, ../../../core/services/vehicle_storage_service.dart, build, _cameraCtrl, _cameras, Captura360Screen, _Captura360ScreenState, _capturarFoto (+23 more)

### Community 16 - "weekly_insight_card.dart"
Cohesion: 0.07
Nodes (29): ai_insights_panel.dart, ../../../../core/logic/fuel_efficiency_logic.dart, core/logic/performance_guard.dart, ../../../core/logic/vehicle_health_logic.dart, ../../../core/theme/brand_theme.dart, ../domain/models/weekly_stats.dart, AchievementsCard, brandTheme (+21 more)

### Community 17 - "gates/index.mjs"
Cohesion: 0.11
Nodes (23): extractColdStarts(), gate(), metadata, GATE_VERSION, gates, MAX_CODE_CANDIDATES, gate(), metadata (+15 more)

### Community 18 - "historial_rutas_screen.dart"
Cohesion: 0.07
Nodes (28): ../../../core/logic/vehicle_ai_logic.dart, ../../../core/services/report_service.dart, _aiInsights, build, _buildAIHeader, _buildEmptyState, color, createState (+20 more)

### Community 19 - "guia.dart"
Cohesion: 0.07
Nodes (28): ImagePicker, _abrirVideo, AccidenteScreen, _AccidenteScreenState, _cargarDatos, color, completado, contenidoExtra (+20 more)

### Community 20 - "support-topics.mjs"
Cohesion: 0.13
Nodes (26): citationApplies(), HERE, KNOWN_CANDIDATE_KINDS, loadSupportTopics(), matchesCandidateKind(), matchesCandidateMetrics(), matchesCandidateRoutePatterns(), matchesFrameworks() (+18 more)

### Community 21 - "gastos_screen.dart"
Cohesion: 0.07
Nodes (27): ../../../core/logic/pdf_report_logic.dart, ../../../core/logic/vehicle_expenses_logic.dart, ../../../core/services/supabase_service.dart, apodo, brandLogoPath, build, _BuildFinancialDashboard, createState (+19 more)

### Community 22 - "report_service.dart"
Cohesion: 0.09
Nodes (24): dart:typed_data, generateAndShareExpenseReport, PdfReportLogic, generateVehicleReport, _getBrandLogoPath, _loadAsset, _loadAssetSafe, _pdfStat (+16 more)

### Community 23 - "SimpleEntry"
Cohesion: 0.11
Nodes (22): Date, Entry, Provider, RunnerWidget, .body, RunnerWidgetEntryView, .body, SimpleEntry (+14 more)

### Community 24 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 25 - "lib/reconcile-candidates.mjs"
Cohesion: 0.26
Nodes (24): arrayAt(), deploymentRegressionDecision(), dropWithObservation(), formatInteger(), formatMs(), formatPct(), isrOverrevalidationDecision(), numberAt() (+16 more)

### Community 26 - "navigation_widgets.dart"
Cohesion: 0.08
Nodes (25): Animation, AnimationController, CustomPainter, _DonutPainter, build, _check, _CheckPainter, color (+17 more)

### Community 27 - "StatelessWidget"
Cohesion: 0.08
Nodes (24): _BuildEmptyState, GuiaScreen, _OpcionCard, _PasoCard, _VideoTutorialCard, build, _buildSpecialOffer, imageUrl (+16 more)

### Community 28 - "auth_provider.dart"
Cohesion: 0.18
Nodes (10): _init, isAuthenticated, _isLoading, signIn, signOut, signUp, _supabaseService, _user (+2 more)

### Community 29 - "sync_service.dart"
Cohesion: 0.08
Nodes (24): Connectivity, _connectivity, _connectivitySubscription, _db, dispose, getCombinedRouteHistory, hasInternetConnection, initialize (+16 more)

### Community 30 - "navigation_controller.dart"
Cohesion: 0.08
Nodes (24): domain/models/navigation_telemetry.dart, double get, LatLng? get, _connectToBackgroundService, destination, destinationName, dispose, _isCar (+16 more)

### Community 31 - "dashboard_widgets.dart"
Cohesion: 0.08
Nodes (24): brandTheme, build, child, color, createState, delay, finesCount, icon (+16 more)

### Community 32 - "investigation-brief.mjs"
Cohesion: 0.19
Nodes (23): absoluteBriefPath(), briefRoots(), buildBrief(), cachePolicyGuidance(), capBriefFiles(), closestAncestorLayoutFiles(), isCatchAllPlaceholder(), isDynamicPlaceholder() (+15 more)

### Community 33 - "scanners/index.mjs"
Cohesion: 0.16
Nodes (16): isApplicable(), metadata, scan(), isApplicable(), metadata, scan(), metadata, scan() (+8 more)

### Community 34 - "background_nav_service.dart"
Cohesion: 0.17
Nodes (12): @pragma, dart:async, backgroundCallback, BackgroundNavService, channelId, initializeService, notificationTitle, onIosBackground (+4 more)

### Community 35 - "database.dart"
Cohesion: 0.08
Nodes (23): AppDatabase, _database, deletePendingExpense, deletePendingKmsUpdate, deletePendingRoute, getPendingExpenses, getPendingKmsUpdates, getPendingRoutes (+15 more)

### Community 36 - "collect-signals.mjs"
Cohesion: 0.16
Nodes (21): defaultNormalize(), normalizeColdStart(), normalizerFor(), QUERIES, TIME_WINDOW, aggregateServicesByName(), filterUsageByProject(), normalizeSummary() (+13 more)

### Community 37 - "liquid_glass_fab.dart"
Cohesion: 0.10
Nodes (22): borderRadius, build, createState, customColors, _handleTapCancel, _handleTapDown, _handleTapUp, height (+14 more)

### Community 38 - "citations.mjs"
Cohesion: 0.18
Nodes (19): compareVersion(), HERE, isKnownUrl(), LIBRARY_PATH, libraryForStack(), loadLibrary(), lookupSkillRule(), lookupUrl() (+11 more)

### Community 39 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.09
Nodes (21): app_links, connectivity_plus, device_info_plus, file_picker, file_selector_macos, firebase_core, firebase_messaging, flutter_local_notifications (+13 more)

### Community 40 - "navigation_telemetry.dart"
Cohesion: 0.09
Nodes (21): Duration, LatLng?, averageSpeedKmH, avgSpeedKmH, copyWith, currentPos, distanceKm, duration (+13 more)

### Community 41 - "supabase_service.dart"
Cohesion: 0.09
Nodes (21): addExpense, authStateChanges, client, createVehicle, currentUser, deleteExpense, getExpenses, getRouteHistory (+13 more)

### Community 42 - "registro_screen.dart"
Cohesion: 0.10
Nodes (21): build, _buildRegistrarTextField, canSwitchEmail, confirmPasswordController, createState, dispose, emailController, isLoading (+13 more)

### Community 43 - "scripts/deep-dive.mjs"
Cohesion: 0.18
Nodes (17): escapeODataString(), mergeIntoEvidence(), odataEq(), SCANNER_KINDS, simplify(), SPEC_GENERATORS, specsForCandidate(), queryMetric() (+9 more)

### Community 44 - "simit_webview.dart"
Cohesion: 0.10
Nodes (20): app_snack_bar.dart, ../../core/services/email_service.dart, build, cedula, _controller, createState, _escanearPagina, _finesCount (+12 more)

### Community 45 - "bitacora_tanqueo_screen.dart"
Cohesion: 0.10
Nodes (20): ../../../core/services/fuel_tracker_service.dart, ../../../core/utils/formatters.dart, ../domain/models/fuel_log_model.dart, _abrirDialogoAgregar, BitacoraTanqueoScreen, _BitacoraTanqueoScreenState, build, _buildInput (+12 more)

### Community 46 - "runt_webview.dart"
Cohesion: 0.10
Nodes (20): build, cedula, consultarFechas, _controller, createState, fechaSoatExpedicion, fechaSoatVencimiento, fechaTecnoExpedicion (+12 more)

### Community 47 - "route-normalize.mjs"
Cohesion: 0.22
Nodes (19): candidateKey(), canonicalizeBranchPrefix(), canonicalizeRoute(), decodeSegmentToken(), dedupeCandidates(), firstRouteSegment(), isBase64FlagState(), isDynamicPlaceholder() (+11 more)

### Community 48 - "Color"
Cohesion: 0.10
Nodes (18): Color, ../domain/models/vehicle_analytics.dart, advice, _asDouble, avgDailyKm, careScore, consistency, empty (+10 more)

### Community 49 - "app_localizations.dart"
Cohesion: 0.11
Nodes (17): app_localizations_en.dart, app_localizations_es.dart, appTitle, delegate, email, isSupported, load, localeName (+9 more)

### Community 50 - "State"
Cohesion: 0.14
Nodes (18): DocumentViewerScreen, _DocumentViewerScreenState, InicioApp, _InicioAppState, Interactive360Spinner, _Interactive360SpinnerState, _ScaleButton, _ScaleButtonState (+10 more)

### Community 51 - "win32_window.cpp"
Cohesion: 0.18
Nodes (14): Point, Size, wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window() (+6 more)

### Community 52 - "collect-sub-agent-outputs.mjs"
Cohesion: 0.24
Nodes (16): collectInputFiles(), escapeRegExp(), extractFenceBlocks(), extractJsonValue(), findBalancedJsonSpans(), inferCandidateRefFromFile(), isRecordObject(), log() (+8 more)

### Community 53 - "merge-signals.mjs"
Cohesion: 0.23
Nodes (16): annotateCodebaseScan(), annotateFinding(), assertObject(), bestRouteSummary(), buildRouteMetricIndex(), exists(), formatRouteSignal(), hasTraffic() (+8 more)

### Community 54 - "main.dart"
Cohesion: 0.12
Nodes (16): core/logic/app_widget_logic.dart, core/providers/auth_provider.dart, core/providers/vehicle_provider.dart, core/services/background_nav_service.dart, core/services/notification_service.dart, core/services/sync_service.dart, features/auth/login_screen.dart, build (+8 more)

### Community 55 - "List"
Cohesion: 0.12
Nodes (15): ../domain/models/maintenance_prediction.dart, aiAnalytics, empty, fromData, routeCount, routeHistory, totalCost, totalGallons (+7 more)

### Community 56 - "navigation_service.dart"
Cohesion: 0.12
Nodes (16): calculateRoute, displayName, distanceKm, durationMin, fromJson, _instance, lat, lon (+8 more)

### Community 57 - "prepare-investigation-brief.mjs"
Cohesion: 0.24
Nodes (15): citationSubset(), inferFrameworkPlaybook(), inferPlaybook(), candidateRefFor(), buildFanoutPlan(), buildManifest(), candidateFamilyKey(), HERE (+7 more)

### Community 58 - "throttle.mjs"
Cohesion: 0.17
Nodes (10): getMetricSemaphore, getMetricThrottle(), isRateLimited(), parsePositiveIntEnv(), resolveConcurrency(), resolveRateLimit(), retryOnRateLimit(), SemaphoreAbortError (+2 more)

### Community 59 - "VehicleStatusWidgetProvider.java"
Cohesion: 0.26
Nodes (11): AppWidgetProvider, Override, Override, VehicleStatusWidgetProvider, android.appwidget.AppWidgetManager, android.content.Context, android.content.SharedPreferences, android.widget.RemoteViews (+3 more)

### Community 60 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.13
Nodes (14): ../../features/expenses/domain/models/fuel_log_model.dart, addLog, _cacheLocal, calculateMetrics, FuelTrackerService, getLogs, _instance, _localKey (+6 more)

### Community 61 - "vehicle_expenses_logic.dart"
Cohesion: 0.12
Nodes (15): IconData, calculateTotal, categories, color, DonutSegment, ExpenseCategory, formatCurrency, getDonutSegments (+7 more)

### Community 62 - "auth_service.dart"
Cohesion: 0.12
Nodes (15): AuthService, currentUser, getFirstVehicleId, _instance, isNotConfirmed, message, resendConfirmationEmail, sendPasswordReset (+7 more)

### Community 63 - "_"
Cohesion: 0.13
Nodes (16): _, AppFormat, currency, currencyFormat, date, _dateFormat, dateTime, _dateTimeFormat (+8 more)

### Community 64 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+5 more)

### Community 65 - "verify-and-regen.mjs"
Cohesion: 0.22
Nodes (14): summarizeClaimResults(), applyQualityFloor(), deriveProjectFacts(), findRecContradictions(), deriveRootFromSignals(), detectRepoRoot(), fileResolvesAt(), pickProbeFile() (+6 more)

### Community 66 - "verifyNextCacheComponentsRouteChainFile"
Cohesion: 0.15
Nodes (15): asArray(), firstAccessiblePath(), firstDynamicRouteChainReason(), isCatchAllPlaceholder(), isDynamicPlaceholder(), layoutAppliesToCandidateRoute(), normalizeProjectRootDirectory(), normalizeRouteForLayoutMatch() (+7 more)

### Community 67 - "readClaimFile"
Cohesion: 0.31
Nodes (9): compilePattern(), readClaimFile(), snippetFoundElsewhere(), verifyCodeSnippet(), verifyPatternAbsent(), verifyPatternCount(), verifyPatternExists(), verifyRepoCount() (+1 more)

### Community 68 - "email_service.dart"
Cohesion: 0.22
Nodes (8): _buildHtmlReport, EmailService, _fmtDate, sendSimitReport, package:flutter_dotenv/flutter_dotenv.dart, package:http/http.dart, package:mailer/mailer.dart, package:mailer/smtp_server.dart

### Community 69 - "verifyNextCacheLifetimeFreshnessSupported"
Cohesion: 0.28
Nodes (9): cacheLifeNeedsContentFreshnessProof(), dedupeCacheTags(), execFileP, extractCacheTags(), extractCacheTagsFromFiles(), readCacheInvalidationFiles(), rgRelevantFiles(), verifyNextCacheLifetimeFreshnessSupported() (+1 more)

### Community 70 - "ai_bot_service.dart"
Cohesion: 0.14
Nodes (13): ChatSession?, GenerativeModel?, AIBotService, _chat, _currentModelName, initialize, _instance, _model (+5 more)

### Community 71 - "fuel_log_model.dart"
Cohesion: 0.14
Nodes (13): DateTime, esTanqueLleno, fecha, fromJson, FuelLogModel, galones, id, kmsActuales (+5 more)

### Community 72 - "vehicle_catalog_service.dart"
Cohesion: 0.14
Nodes (13): _brandColors, _carCatalog, _carLogos, getBrandColors, getCarCatalog, getCarLogos, getMotoCatalog, getMotoLogos (+5 more)

### Community 73 - "vehicle_storage_service.dart"
Cohesion: 0.14
Nodes (13): _bucketName, deleteDocument, getSignedUrl, _instance, listFolder, message, _supabase, toString (+5 more)

### Community 74 - "MaterialPageRoute"
Cohesion: 0.14
Nodes (14): build, build, _buildIssueItem, _buildTopSearch, _abrirBitacoraTanqueo, _abrirGarajeSelector, _abrirGuias, _abrirHistorialRutas (+6 more)

### Community 75 - "Win32Window"
Cohesion: 0.20
Nodes (14): RECT, OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate (+6 more)

### Community 76 - "vehicle_ai_logic.dart"
Cohesion: 0.15
Nodes (11): dart:math, calculateEfficiencyScore, calculateSavings, FuelEfficiencyLogic, getEfficiencyLabel, analyzeJourneyPatterns, _calculateCareScore, calculateSmartSavings (+3 more)

### Community 77 - "maintenance_config_service.dart"
Cohesion: 0.15
Nodes (12): cycleDays, _cycles, getAllCycles, getCycle, getKmsCycle, _instance, _kmsCycles, MaintenanceConfig (+4 more)

### Community 78 - "grade-recommendation.mjs"
Cohesion: 0.39
Nodes (11): grade(), gradeRecommendation(), isAccountScope(), roundTo(), scoreActionability(), scoreEvidence(), scoreEvidenceAccount(), scoreGrounding() (+3 more)

### Community 79 - "app_localizations_en.dart"
Cohesion: 0.18
Nodes (10): app_localizations.dart, appTitle, email, login, password, appTitle, email, login (+2 more)

### Community 80 - "telemetry_calculator.dart"
Cohesion: 0.17
Nodes (10): ../../../core/logic/vehicle_performance_logic.dart, calculateAverageSpeed, calculateIncrementalDistance, estimateImpact, optimizeRoutePoints, TelemetryCalculator, package:geolocator/geolocator.dart, package:latlong2/latlong.dart (+2 more)

### Community 81 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 82 - "gate-investigations.mjs"
Cohesion: 0.33
Nodes (9): applyAuthDisqualifier(), AUTH_ROUTE_REGEX, isAuthRoute(), DEFAULT_MAX_CODE_CANDIDATES, attachDisplayRoute(), main(), parseArgs(), resolveBudget() (+1 more)

### Community 83 - "withRouteShapeWarnings"
Cohesion: 0.29
Nodes (9): extractErrors(), extractFromStatusRows(), gate(), metadata, extractErrorRatesByRoute(), extractFunctionRoutes(), gate(), metadata (+1 more)

### Community 84 - "brand_theme.dart"
Cohesion: 0.18
Nodes (10): accentColor, BrandTheme, defaultTheme, getTheme, gradient, primaryColor, _themes, LinearGradient (+2 more)

### Community 85 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 86 - "hard-gates.mjs"
Cohesion: 0.36
Nodes (9): applyHardGates(), FLAGS_ENDPOINT, flagsEndpointReason(), isFlagsEndpointCandidate(), isWorkflowRuntimeEndpointCandidate(), normalizeRoute(), VERCEL_FLAGS_PACKAGES, WORKFLOW_ENDPOINT_PREFIXES (+1 more)

### Community 87 - "uncached-route.mjs"
Cohesion: 0.24
Nodes (8): Candidate, CandidateScope, GateMetadata, Signals, extractCacheHitRates(), extractMethodShares(), gate(), metadata

### Community 89 - "vehicle_health_logic.dart"
Cohesion: 0.20
Nodes (9): calculateHealthIndex, calculateHybridPercentage, getProactiveAdvice, getQualityCertifications, getUserLevel, getVehicleStatus, getWeeklySummary, predictMaintenance (+1 more)

### Community 90 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 91 - "scanner-driven.mjs"
Cohesion: 0.36
Nodes (8): candidateForGroup(), gate(), groupFindings(), metadata, observedCacheHitRate(), questionFor(), SCANNER_GATES, uniqueStrings()

### Community 92 - "select-candidates.mjs"
Cohesion: 0.42
Nodes (8): candidateIdentity(), DEFAULT_KIND_CAPS, DIVERSITY_ELIGIBILITY, durationMsFromSignal(), isDiversityEligible(), numberFromEvidence(), numberFromSignal(), selectLaunchCandidates()

### Community 93 - ".application"
Cohesion: 0.25
Nodes (6): Any, Flutter, AppDelegate, Bool, UIApplication, UIKit

### Community 94 - "performance_guard.dart"
Cohesion: 0.20
Nodes (9): bool get, dart:ui, adaptiveBlur, initialize, _instance, _isLowEnd, PerformanceGuard, package:device_info_plus/device_info_plus.dart (+1 more)

### Community 95 - "contract.mjs"
Cohesion: 0.39
Nodes (6): CandidateContractError, candidateLabel(), nonEmptyString(), VALID_SCOPES, validateCandidate(), validateCandidates()

### Community 96 - "rendering-mode-mislabel.mjs"
Cohesion: 0.32
Nodes (6): apply(), metadata, apply(), metadata, MODE_PATTERNS, extractRoute()

### Community 97 - "large-static-asset.mjs"
Cohesion: 0.43
Nodes (7): formatBytes(), metadata, scan(), shouldSkip(), SKIP_EXTENSIONS, SKIP_PATH_PREFIXES, walk()

### Community 98 - "docs-library.json"
Cohesion: 0.25
Nodes (7): applicableFrameworksSyntax, lastVerified, ruleSkillRefs, $schema, schemaVersion, urls, version

### Community 99 - "maintenance_prediction.dart"
Cohesion: 0.25
Nodes (7): fromList, fromMap, isCritical, item, MaintenancePrediction, reason, risk

### Community 100 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (6): AgregarCarroScreen, build, AgregarVehiculoScreen, build, package:flutter/material.dart, widgets/vehicle_registration_view.dart

### Community 101 - "framework-support.mjs"
Cohesion: 0.52
Nodes (6): classifyFrameworkSupport(), CORE_SUPPORTED_FRAMEWORKS, frameworkLabel(), LABELS, LIMITED_FRAMEWORKS, normalizeFramework()

### Community 102 - "cwv-poor.mjs"
Cohesion: 0.48
Nodes (6): byRoute(), gate(), metadata, ratioOverThreshold(), round2(), sumRows()

### Community 103 - "cache-components-suspense-dedupe.mjs"
Cohesion: 0.48
Nodes (6): countMatches(), findRepeated(), metadata, record(), scan(), truncate()

### Community 104 - "edge-heavy-import.mjs"
Cohesion: 0.52
Nodes (6): extractSpecifiers(), HEAVY_PATTERNS, isEdgeRuntimeFile(), isMiddleware(), metadata, scan()

### Community 105 - "turbo-force-bypass.mjs"
Cohesion: 0.48
Nodes (6): detectBuildCacheDisabled(), lineOfMatch(), metadata, safeScripts(), scan(), truncate()

### Community 106 - "use-cache-date-stamp.mjs"
Cohesion: 0.48
Nodes (6): classifySubtype(), collectRanges(), findMatchingParen(), isInsideAnyRange(), metadata, scan()

### Community 107 - "vehicle_performance_logic.dart"
Cohesion: 0.29
Nodes (6): _calculateEfficiencyFactor, estimateFuelConsumption, estimateFuelCost, extractCC, getKmPerGalon, VehiclePerformanceLogic

### Community 110 - "unoptimized-image.mjs"
Cohesion: 0.53
Nodes (5): isJsxLike(), isNextConfig(), metadata, scan(), snippet()

### Community 111 - "FlutterMacOS"
Cohesion: 0.47
Nodes (3): Cocoa, FlutterMacOS, XCTest

### Community 112 - "AppDelegate"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 113 - "RegisterGeneratedPlugins"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 114 - "AppLocalizations"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, AppLocalizationsEs, of, LocalizationsDelegate

### Community 115 - "external-api-slow.mjs"
Cohesion: 0.60
Nodes (4): extractCallCounts(), extractExternalApis(), gate(), metadata

### Community 116 - "platform-bot-protection.mjs"
Cohesion: 0.60
Nodes (4): computeBotShare(), gate(), metadata, totalRequestsFromSignals()

### Community 117 - "platform-fluid-compute.mjs"
Cohesion: 0.60
Nodes (4): extractHighColdRoutes(), extractSlowHotRoutes(), gate(), metadata

### Community 118 - "usage-spike-triage.mjs"
Cohesion: 0.60
Nodes (4): aggregateSkuStats(), dayTotal(), gate(), metadata

### Community 119 - "verify-claim.mjs"
Cohesion: 0.11
Nodes (31): buildScriptHasMigrationSideEffect(), cacheInvalidationFileCache, cleanHeaderValue(), configContainsTag(), escapeRegExp(), extractHeaderValues(), formatPct(), functionStatusForRoute() (+23 more)

### Community 120 - "MainActivity.kt"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterEngine, FlutterFragmentActivity

### Community 121 - "RunnerTests"
Cohesion: 0.40
Nodes (3): RunnerTests, RunnerTests, XCTestCase

### Community 122 - "calendar_sync_service.dart"
Cohesion: 0.40
Nodes (4): addEventToCalendar, CalendarSyncService, package:intl/intl.dart, package:url_launcher/url_launcher.dart

### Community 123 - "build-minutes-fanout.mjs"
Cohesion: 0.67
Nodes (3): gate(), metadata, unique()

### Community 124 - "isr-overrevalidation.mjs"
Cohesion: 0.67
Nodes (3): extractRows(), gate(), metadata

### Community 125 - "middleware-heavy.mjs"
Cohesion: 0.67
Nodes (3): gate(), metadata, sumRows()

### Community 126 - "middleware-broad-matcher.mjs"
Cohesion: 0.67
Nodes (3): isApplicable(), metadata, scan()

### Community 127 - "missing-cache-headers.mjs"
Cohesion: 0.67
Nodes (3): isApplicable(), metadata, scan()

### Community 128 - "Exception"
Cohesion: 0.50
Nodes (4): Exception, AuthLogicException, NavigationLogicException, VehicleStorageLogicException

### Community 142 - "dart:io"
Cohesion: 0.13
Nodes (13): dart:convert, dart:io, dispose, extractExpirationDate, OCRService, _parseFlexibleDate, _textRecognizer, package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart (+5 more)

### Community 143 - "biometric_service.dart"
Cohesion: 0.17
Nodes (12): auth, authenticate, BiometricService, isBiometricAvailable, _, AppSnackBar, show, LocalAuthentication (+4 more)

### Community 144 - "app_widget_logic.dart"
Cohesion: 0.18
Nodes (10): androidWidgetName, AppWidgetLogic, healthWidgetName, initializeWidgetInteraction, _renderCircularIndicator, updateHealthWidget, updateWidget, package:flutter_background_service/flutter_background_service.dart (+2 more)

### Community 145 - "vehicle_provider.dart"
Cohesion: 0.22
Nodes (8): addVehicle, _isLoading, loadVehicles, _supabaseService, updateVehicleKms, _vehicles, SupabaseService, ../services/supabase_service.dart

### Community 146 - "ChangeNotifier"
Cohesion: 0.50
Nodes (4): ChangeNotifier, AuthProvider, VehicleProvider, NavigationController

### Community 147 - "_RutasScreenState"
Cohesion: 0.67
Nodes (3): RutasScreen, _RutasScreenState, TickerProviderStateMixin

## Knowledge Gaps
- **950 isolated node(s):** `Candidate`, `CandidateScope`, `GateMetadata`, `Signals`, `_agendarCalendarioDoc` (+945 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `gates` connect `gates/index.mjs` to `lib/render-report.mjs`, `gate-investigations.mjs`, `support-topics.mjs`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `scanners` connect `gates/index.mjs` to `scanners/index.mjs`, `workspace-resolver.mjs`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `Candidate`, `CandidateScope`, `GateMetadata` to the rest of the system?**
  _950 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `inicio_app.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02127659574468085 - nodes in this community are weakly interconnected._
- **Should `lib/render-report.mjs` be split into smaller, more focused modules?**
  _Cohesion score 0.05225885225885226 - nodes in this community are weakly interconnected._
- **Should `dedup-recs.mjs` be split into smaller, more focused modules?**
  _Cohesion score 0.07853107344632769 - nodes in this community are weakly interconnected._
- **Should `sanitizers/index.mjs` be split into smaller, more focused modules?**
  _Cohesion score 0.0514216575922565 - nodes in this community are weakly interconnected._