# Graph Report - my_auto_guide  (2026-08-15)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1469 nodes · 1926 edges · 86 communities (82 shown, 4 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 19 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b4a1df39`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- inicio_app.dart
- Win32Window
- gastos_screen.dart
- vehicle_registration_view.dart
- rutas_screen.dart
- parametrizacion_mantenimientos.dart
- navigation_telemetry.dart
- notification_service.dart
- package:flutter_test/flutter_test.dart
- login_screen.dart
- captura_360_screen.dart
- historial_rutas_screen.dart
- SimpleEntry
- my_application.cc
- guia.dart
- vehicle_catalog_service.dart
- dashboard_widgets.dart
- sync_service.dart
- navigation_controller.dart
- performance_guard.dart
- GeneratedPluginRegistrant.swift
- bitacora_tanqueo_screen.dart
- simit_webview.dart
- supabase_service.dart
- registro_screen.dart
- liquid_glass_fab.dart
- navigation_widgets.dart
- ai_chat_screen.dart
- app_localizations.dart
- main.dart
- report_service.dart
- weekly_insight_card.dart
- navigation_service.dart
- VehicleStatusWidgetProvider.java
- vehicle_expenses_logic.dart
- auth_service.dart
- _
- StatelessWidget
- ai_bot_service.dart
- vehicle_storage_service.dart
- MaterialPageRoute
- background_nav_service.dart
- achievements_card.dart
- StatefulWidget
- app_localizations_en.dart
- telemetry_calculator.dart
- wWinMain
- glass_text_field.dart
- fuel_tracker_service.dart
- app_widget_logic.dart
- auth_provider.dart
- brand_theme.dart
- weekly_stats.dart
- package:flutter/material.dart
- manifest.json
- vehicle_provider.dart
- vehicle_health_logic.dart
- State
- .application
- Color
- package:supabase_flutter/supabase_flutter.dart
- email_service.dart
- marketplace_talleres_screen.dart
- maintenance_prediction.dart
- vehicle_performance_logic.dart
- SingleTickerProviderStateMixin
- FlutterMacOS
- dart:convert
- List
- AppDelegate
- RegisterGeneratedPlugins
- AppLocalizations
- MainActivity.kt
- RunnerTests
- calendar_sync_service.dart
- ChangeNotifier
- Captura360Screen
- double?
- String?
- Widget

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `_` - 19 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `SimpleEntry` - 9 edges
8. `MessageHandler` - 9 edges
9. `Provider` - 8 edges
10. `WindowClassRegistrar` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `Create` --calls--> `Scale()`  [EXTRACTED]
  windows/runner/win32_window.h → windows/runner/win32_window.cpp
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (86 total, 4 thin omitted)

### Community 0 - "inicio_app.dart"
Cohesion: 0.02
Nodes (93): Agregar_carro.dart, Agregar_vehiculo.dart, ../../ai_bot/presentation/ai_chat_screen.dart, ../../auth/login_screen.dart, captura_360_screen.dart, ../../../core/services/calendar_sync_service.dart, ../../../core/services/vehicle_pdf_report_service.dart, ../../expenses/presentation/bitacora_tanqueo_screen.dart (+85 more)

### Community 1 - "Win32Window"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "gastos_screen.dart"
Cohesion: 0.05
Nodes (42): ../../../core/logic/pdf_report_logic.dart, ../../../core/logic/vehicle_expenses_logic.dart, ../../../core/services/supabase_service.dart, CustomPainter, dart:math, calculateEfficiencyScore, calculateSavings, FuelEfficiencyLogic (+34 more)

### Community 3 - "vehicle_registration_view.dart"
Cohesion: 0.05
Nodes (40): ../../../../core/services/vehicle_catalog_service.dart, ../inicio_app.dart, _apodoController, brandColors, build, _buildField, _cambiarMarca, catalogo (+32 more)

### Community 4 - "rutas_screen.dart"
Cohesion: 0.05
Nodes (36): ../../../core/services/navigation_service.dart, _animCtrl, build, _buildBottomPanel, _buildMap, _buscarDestino, _cargarInfoVehiculo, _controller (+28 more)

### Community 5 - "parametrizacion_mantenimientos.dart"
Cohesion: 0.06
Nodes (35): class, ../../../core/services/ocr_service.dart, _aceite, build, _buildKmInput, _buildMaintenanceCard, _cadena, createState (+27 more)

### Community 6 - "navigation_telemetry.dart"
Cohesion: 0.06
Nodes (34): DateTime, Duration, LatLng?, esTanqueLleno, fecha, fromJson, FuelLogModel, galones (+26 more)

### Community 7 - "notification_service.dart"
Cohesion: 0.08
Nodes (23): dart:io, FlutterLocalNotificationsPlugin, cancelAll, ensureExactAlarmsEnabled, init, _instance, NotificationService, _notificationsPlugin (+15 more)

### Community 8 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.06
Nodes (23): package:flutter_test/flutter_test.dart, package:my_auto_guide/core/logic/fuel_efficiency_logic.dart, package:my_auto_guide/core/logic/vehicle_ai_logic.dart, package:my_auto_guide/core/logic/vehicle_expenses_logic.dart, package:my_auto_guide/core/logic/vehicle_health_logic.dart, package:my_auto_guide/core/logic/vehicle_performance_logic.dart, package:my_auto_guide/features/expenses/domain/models/fuel_log_model.dart, package:my_auto_guide/features/navigation/logic/telemetry_calculator.dart (+15 more)

### Community 9 - "login_screen.dart"
Cohesion: 0.07
Nodes (30): ../../core/services/auth_service.dart, ../../core/services/biometric_service.dart, _auth, _biometric, _bootstrapSession, canUseBiometrics, CarRentalLoginScreen, _CarRentalLoginScreenState (+22 more)

### Community 10 - "captura_360_screen.dart"
Cohesion: 0.07
Nodes (29): CameraController?, ../../../core/services/vehicle_storage_service.dart, build, _cameraCtrl, _cameras, _capturarFoto, _capturedPhotos, color (+21 more)

### Community 11 - "historial_rutas_screen.dart"
Cohesion: 0.07
Nodes (28): ../../../core/logic/vehicle_ai_logic.dart, ../../../core/services/report_service.dart, _aiInsights, build, _buildAIHeader, _buildEmptyState, color, createState (+20 more)

### Community 12 - "SimpleEntry"
Cohesion: 0.11
Nodes (22): Date, Entry, Provider, RunnerWidget, .body, RunnerWidgetEntryView, .body, SimpleEntry (+14 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 14 - "guia.dart"
Cohesion: 0.07
Nodes (28): ImagePicker, _abrirVideo, AccidenteScreen, _AccidenteScreenState, _cargarDatos, color, completado, contenidoExtra (+20 more)

### Community 15 - "vehicle_catalog_service.dart"
Cohesion: 0.07
Nodes (25): cycleDays, _cycles, getAllCycles, getCycle, getKmsCycle, _instance, _kmsCycles, MaintenanceConfig (+17 more)

### Community 16 - "dashboard_widgets.dart"
Cohesion: 0.08
Nodes (23): brandTheme, build, child, color, createState, delay, finesCount, icon (+15 more)

### Community 17 - "sync_service.dart"
Cohesion: 0.04
Nodes (47): Connectivity, AppDatabase, _database, deletePendingExpense, deletePendingKmsUpdate, deletePendingRoute, getPendingExpenses, getPendingKmsUpdates (+39 more)

### Community 18 - "navigation_controller.dart"
Cohesion: 0.08
Nodes (24): domain/models/navigation_telemetry.dart, double get, LatLng? get, _connectToBackgroundService, destination, destinationName, dispose, _isCar (+16 more)

### Community 19 - "performance_guard.dart"
Cohesion: 0.20
Nodes (9): bool get, dart:ui, adaptiveBlur, initialize, _instance, _isLowEnd, PerformanceGuard, package:device_info_plus/device_info_plus.dart (+1 more)

### Community 20 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.09
Nodes (21): app_links, connectivity_plus, device_info_plus, file_picker, file_selector_macos, firebase_core, firebase_messaging, flutter_local_notifications (+13 more)

### Community 21 - "bitacora_tanqueo_screen.dart"
Cohesion: 0.10
Nodes (21): ../../../core/services/fuel_tracker_service.dart, ../../../core/utils/formatters.dart, ../domain/models/fuel_log_model.dart, _abrirDialogoAgregar, BitacoraTanqueoScreen, _BitacoraTanqueoScreenState, build, _buildInput (+13 more)

### Community 22 - "simit_webview.dart"
Cohesion: 0.05
Nodes (40): app_snack_bar.dart, ../../core/services/email_service.dart, build, cedula, consultarFechas, _controller, createState, fechaSoatExpedicion (+32 more)

### Community 23 - "supabase_service.dart"
Cohesion: 0.09
Nodes (21): addExpense, authStateChanges, client, createVehicle, currentUser, deleteExpense, getExpenses, getRouteHistory (+13 more)

### Community 24 - "registro_screen.dart"
Cohesion: 0.10
Nodes (20): build, _buildRegistrarTextField, canSwitchEmail, confirmPasswordController, createState, dispose, emailController, isLoading (+12 more)

### Community 25 - "liquid_glass_fab.dart"
Cohesion: 0.11
Nodes (18): borderRadius, build, createState, customColors, dispose, height, icon, iconSize (+10 more)

### Community 27 - "navigation_widgets.dart"
Cohesion: 0.10
Nodes (20): Animation, AnimationController, build, _check, color, _controller, createState, dispose (+12 more)

### Community 28 - "ai_chat_screen.dart"
Cohesion: 0.11
Nodes (18): ../../core/services/ai_bot_service.dart, AIChatScreen, _AIChatScreenState, build, _buildInputArea, _ChatBubble, createState, isBot (+10 more)

### Community 29 - "app_localizations.dart"
Cohesion: 0.11
Nodes (17): app_localizations_en.dart, app_localizations_es.dart, appTitle, delegate, email, isSupported, load, localeName (+9 more)

### Community 30 - "main.dart"
Cohesion: 0.12
Nodes (16): core/logic/app_widget_logic.dart, core/providers/auth_provider.dart, core/providers/vehicle_provider.dart, core/services/background_nav_service.dart, core/services/notification_service.dart, core/services/sync_service.dart, features/auth/login_screen.dart, build (+8 more)

### Community 31 - "report_service.dart"
Cohesion: 0.07
Nodes (33): dart:typed_data, generateAndShareExpenseReport, PdfReportLogic, auth, authenticate, BiometricService, isBiometricAvailable, generateVehicleReport (+25 more)

### Community 32 - "weekly_insight_card.dart"
Cohesion: 0.12
Nodes (16): ai_insights_panel.dart, ../../../../core/logic/fuel_efficiency_logic.dart, brandTheme, build, color, icon, isLoading, modelName (+8 more)

### Community 33 - "navigation_service.dart"
Cohesion: 0.12
Nodes (16): calculateRoute, displayName, distanceKm, durationMin, fromJson, _instance, lat, lon (+8 more)

### Community 34 - "VehicleStatusWidgetProvider.java"
Cohesion: 0.26
Nodes (11): AppWidgetProvider, Override, Override, VehicleStatusWidgetProvider, android.appwidget.AppWidgetManager, android.content.Context, android.content.SharedPreferences, android.widget.RemoteViews (+3 more)

### Community 35 - "vehicle_expenses_logic.dart"
Cohesion: 0.12
Nodes (15): IconData, calculateTotal, categories, color, DonutSegment, ExpenseCategory, formatCurrency, getDonutSegments (+7 more)

### Community 36 - "auth_service.dart"
Cohesion: 0.12
Nodes (15): AuthService, currentUser, getFirstVehicleId, _instance, isNotConfirmed, message, resendConfirmationEmail, sendPasswordReset (+7 more)

### Community 37 - "_"
Cohesion: 0.13
Nodes (16): _, AppFormat, currency, currencyFormat, date, _dateFormat, dateTime, _dateTimeFormat (+8 more)

### Community 38 - "StatelessWidget"
Cohesion: 0.11
Nodes (18): _SocialButton, _BuildFinancialDashboard, GuiaScreen, _OpcionCard, _PasoCard, _VideoTutorialCard, DashedLineConnector, _LocationRow (+10 more)

### Community 39 - "ai_bot_service.dart"
Cohesion: 0.14
Nodes (13): ChatSession?, GenerativeModel?, AIBotService, _chat, _currentModelName, initialize, _instance, _model (+5 more)

### Community 40 - "vehicle_storage_service.dart"
Cohesion: 0.14
Nodes (13): _bucketName, deleteDocument, getSignedUrl, _instance, listFolder, message, _supabase, toString (+5 more)

### Community 41 - "MaterialPageRoute"
Cohesion: 0.14
Nodes (14): build, build, _buildIssueItem, _buildTopSearch, _abrirBitacoraTanqueo, _abrirGarajeSelector, _abrirGuias, _abrirHistorialRutas (+6 more)

### Community 42 - "background_nav_service.dart"
Cohesion: 0.17
Nodes (12): @pragma, dart:async, backgroundCallback, BackgroundNavService, channelId, initializeService, notificationTitle, onIosBackground (+4 more)

### Community 43 - "achievements_card.dart"
Cohesion: 0.15
Nodes (12): ../../../core/logic/vehicle_health_logic.dart, ../../../core/theme/brand_theme.dart, ../domain/models/weekly_stats.dart, AchievementsCard, brandTheme, build, documentsComplete, _getIconData (+4 more)

### Community 44 - "StatefulWidget"
Cohesion: 0.17
Nodes (12): RutasScreen, _RutasScreenState, InicioApp, _InicioAppState, Interactive360Spinner, _Interactive360SpinnerState, _ScaleButton, _StaggeredFadeIn (+4 more)

### Community 45 - "app_localizations_en.dart"
Cohesion: 0.18
Nodes (10): app_localizations.dart, appTitle, email, login, password, appTitle, email, login (+2 more)

### Community 46 - "telemetry_calculator.dart"
Cohesion: 0.17
Nodes (10): ../../../core/logic/vehicle_performance_logic.dart, calculateAverageSpeed, calculateIncrementalDistance, estimateImpact, optimizeRoutePoints, TelemetryCalculator, package:geolocator/geolocator.dart, package:latlong2/latlong.dart (+2 more)

### Community 47 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 48 - "glass_text_field.dart"
Cohesion: 0.18
Nodes (10): core/logic/performance_guard.dart, build, controller, GlassTextField, icon, keyboardType, label, obscureText (+2 more)

### Community 49 - "fuel_tracker_service.dart"
Cohesion: 0.18
Nodes (10): ../../features/expenses/domain/models/fuel_log_model.dart, addLog, _cacheLocal, calculateMetrics, FuelTrackerService, getLogs, _instance, _localKey (+2 more)

### Community 50 - "app_widget_logic.dart"
Cohesion: 0.18
Nodes (10): androidWidgetName, AppWidgetLogic, healthWidgetName, initializeWidgetInteraction, _renderCircularIndicator, updateHealthWidget, updateWidget, package:flutter_background_service/flutter_background_service.dart (+2 more)

### Community 51 - "auth_provider.dart"
Cohesion: 0.18
Nodes (10): _init, isAuthenticated, _isLoading, signIn, signOut, signUp, _supabaseService, _user (+2 more)

### Community 52 - "brand_theme.dart"
Cohesion: 0.18
Nodes (10): accentColor, BrandTheme, defaultTheme, getTheme, gradient, primaryColor, _themes, LinearGradient (+2 more)

### Community 53 - "weekly_stats.dart"
Cohesion: 0.09
Nodes (20): advice, _asDouble, avgDailyKm, careScore, consistency, empty, fromMap, healthImpact (+12 more)

### Community 55 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (9): AgregarCarroScreen, build, AgregarVehiculoScreen, build, _, AppSnackBar, show, package:flutter/material.dart (+1 more)

### Community 56 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 57 - "vehicle_provider.dart"
Cohesion: 0.22
Nodes (8): addVehicle, _isLoading, loadVehicles, _supabaseService, updateVehicleKms, _vehicles, SupabaseService, ../services/supabase_service.dart

### Community 58 - "vehicle_health_logic.dart"
Cohesion: 0.20
Nodes (9): calculateHealthIndex, calculateHybridPercentage, getProactiveAdvice, getQualityCertifications, getUserLevel, getVehicleStatus, getWeeklySummary, predictMaintenance (+1 more)

### Community 60 - "State"
Cohesion: 0.28
Nodes (9): DocumentViewerScreen, _DocumentViewerScreenState, _ScaleButtonState, _StaggeredFadeInState, _ScaleButtonState, _StaggeredFadeInState, ScaleButton, StaggeredFadeIn (+1 more)

### Community 61 - ".application"
Cohesion: 0.25
Nodes (6): Any, Flutter, AppDelegate, Bool, UIApplication, UIKit

### Community 62 - "Color"
Cohesion: 0.22
Nodes (8): Color, ../domain/models/vehicle_analytics.dart, _AIBadge, AIInsightsPanel, analytics, build, color, label

### Community 63 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.22
Nodes (8): Exception, AuthLogicException, NavigationLogicException, VehicleStorageLogicException, package:my_auto_guide/core/providers/auth_provider.dart, package:shared_preferences/shared_preferences.dart, package:supabase_flutter/supabase_flutter.dart, main

### Community 64 - "email_service.dart"
Cohesion: 0.22
Nodes (8): _buildHtmlReport, EmailService, _fmtDate, sendSimitReport, package:flutter_dotenv/flutter_dotenv.dart, package:http/http.dart, package:mailer/mailer.dart, package:mailer/smtp_server.dart

### Community 66 - "marketplace_talleres_screen.dart"
Cohesion: 0.22
Nodes (8): build, _buildSpecialOffer, imageUrl, isDark, MarketplaceTalleresScreen, rating, _WorkshopCard, String name, category, distance,

### Community 67 - "maintenance_prediction.dart"
Cohesion: 0.25
Nodes (7): fromList, fromMap, isCritical, item, MaintenancePrediction, reason, risk

### Community 68 - "vehicle_performance_logic.dart"
Cohesion: 0.29
Nodes (6): _calculateEfficiencyFactor, estimateFuelConsumption, estimateFuelCost, extractCC, getKmPerGalon, VehiclePerformanceLogic

### Community 69 - "SingleTickerProviderStateMixin"
Cohesion: 0.29
Nodes (7): PulsingLocationMarker, _PulsingLocationMarkerState, LiquidGlassButton, _LiquidGlassButtonState, LiquidGlassFAB, _LiquidGlassFABState, SingleTickerProviderStateMixin

### Community 70 - "FlutterMacOS"
Cohesion: 0.47
Nodes (3): Cocoa, FlutterMacOS, XCTest

### Community 71 - "dart:convert"
Cohesion: 0.33
Nodes (5): dart:convert, RegExp, libDir, main, opacityRegex

### Community 72 - "List"
Cohesion: 0.33
Nodes (5): ../domain/models/maintenance_prediction.dart, build, predictions, ProactivePredictionsCard, List

### Community 73 - "AppDelegate"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 74 - "RegisterGeneratedPlugins"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 75 - "AppLocalizations"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsEn, AppLocalizationsEs, of, LocalizationsDelegate

### Community 76 - "MainActivity.kt"
Cohesion: 0.60
Nodes (3): MainActivity, FlutterEngine, FlutterFragmentActivity

### Community 77 - "RunnerTests"
Cohesion: 0.40
Nodes (3): RunnerTests, RunnerTests, XCTestCase

### Community 78 - "calendar_sync_service.dart"
Cohesion: 0.40
Nodes (4): addEventToCalendar, CalendarSyncService, package:intl/intl.dart, package:url_launcher/url_launcher.dart

### Community 79 - "ChangeNotifier"
Cohesion: 0.50
Nodes (4): ChangeNotifier, AuthProvider, VehicleProvider, NavigationController

## Knowledge Gaps
- **854 isolated node(s):** `_agendarCalendarioDoc`, `_asDouble`, `brandLogos`, `brandTheme`, `_buildLegalAlerts` (+849 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `app_widget_logic.dart`, `calendar_sync_service.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `VehicleAnalytics` connect `weekly_stats.dart` to `Color`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `_agendarCalendarioDoc`, `_asDouble`, `brandLogos` to the rest of the system?**
  _854 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `inicio_app.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02127659574468085 - nodes in this community are weakly interconnected._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `gastos_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Should `vehicle_registration_view.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05121951219512195 - nodes in this community are weakly interconnected._