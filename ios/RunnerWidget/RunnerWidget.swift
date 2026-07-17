import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), distance: 0.0, isTracking: false, cadenaPath: "", filtroPath: "", aceitePath: "", soatPath: "", tecnoPath: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = readData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = readData()
        // Re-generar el timeline cada vez que haya actualizaciones
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func readData() -> SimpleEntry {
        // suiteName debe coincidir con el App Group configurado en Apple Developer Portal
        let defaults = UserDefaults(suiteName: "group.my_auto_guide")
        let distance = defaults?.double(forKey: "current_distance") ?? 0.0
        let isTracking = defaults?.bool(forKey: "is_tracking") ?? false
        let cadenaPath = defaults?.string(forKey: "widget_cadena") ?? ""
        let filtroPath = defaults?.string(forKey: "widget_filtro") ?? ""
        let aceitePath = defaults?.string(forKey: "widget_aceite") ?? ""
        let soatPath = defaults?.string(forKey: "widget_soat") ?? ""
        let tecnoPath = defaults?.string(forKey: "widget_tecno") ?? ""
        
        return SimpleEntry(
            date: Date(),
            distance: distance,
            isTracking: isTracking,
            cadenaPath: cadenaPath,
            filtroPath: filtroPath,
            aceitePath: aceitePath,
            soatPath: soatPath,
            tecnoPath: tecnoPath
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let distance: Double
    let isTracking: Bool
    let cadenaPath: String
    let filtroPath: String
    let aceitePath: String
    let soatPath: String
    let tecnoPath: String
}

struct RunnerWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            if entry.isTracking {
                // Widget de Navegación Activa
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("Trayecto en Curso")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    Text(String(format: "%.1f KM", entry.distance))
                        .font(.system(size: 26, weight: .black))
                        .minimumScaleFactor(0.8)
                    Text("Registrando telemetría...")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
            } else {
                // Widget de Salud del Vehículo
                VStack(spacing: 6) {
                    Text("Salud de mi Vehículo")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        WidgetImage(path: entry.aceitePath, fallbackLabel: "Aceite")
                        WidgetImage(path: entry.cadenaPath, fallbackLabel: "Cadena")
                        WidgetImage(path: entry.filtroPath, fallbackLabel: "Filtro")
                        WidgetImage(path: entry.soatPath, fallbackLabel: "SOAT")
                        WidgetImage(path: entry.tecnoPath, fallbackLabel: "Tecno")
                    }
                }
            }
        }
        .padding(10)
    }
}

struct WidgetImage: View {
    let path: String
    let fallbackLabel: String
    
    var body: some View {
        VStack(spacing: 2) {
            if !path.isEmpty, let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
            } else {
                VStack {
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.5))
                    Text(fallbackLabel)
                        .font(.system(size: 7))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 38, height: 38)
            }
        }
    }
}

@main
struct RunnerWidget: Widget {
    let kind: String = "RunnerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RunnerWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
        }
        .configurationDisplayName("My Auto Guide Widget")
        .description("Visualiza la salud de tu vehículo y el progreso de tus rutas en tiempo real.")
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}
