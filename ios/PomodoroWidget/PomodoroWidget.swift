import WidgetKit
import SwiftUI

struct PomodoroEntry: TimelineEntry {
    let date: Date
    let species: String
    let pot: String
    let progress: Double
    let subject: String
    let streak: Int
    let phaseName: String
    let plantImagePath: String?
}

struct PomodoroTimelineProvider: TimelineProvider {
    let appGroupId = "group.com.example.miAppUniversitaria"

    func placeholder(in context: Context) -> PomodoroEntry {
        PomodoroEntry(
            date: Date(),
            species: "sp_oak",
            pot: "pot_default",
            progress: 0.65,
            subject: "Cálculo I",
            streak: 3,
            phaseName: "Planta Madura",
            plantImagePath: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroEntry) -> Void) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroEntry>) -> Void) {
        let entry = getEntry()
        // Actualiza periódicamente
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 20, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntry() -> PomodoroEntry {
        let defaults = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
        let species = defaults.string(forKey: "species") ?? "sp_oak"
        let pot = defaults.string(forKey: "pot") ?? "pot_default"
        let progress = defaults.object(forKey: "progress") != nil ? defaults.double(forKey: "progress") : 0.65
        let subject = defaults.string(forKey: "subject") ?? "Enfoque UPEA"
        let streak = defaults.integer(forKey: "streak") > 0 ? defaults.integer(forKey: "streak") : 3
        let phaseName = defaults.string(forKey: "phaseName") ?? "En Crecimiento"
        let plantImagePath = defaults.string(forKey: "plant_graphic")

        return PomodoroEntry(
            date: Date(),
            species: species,
            pot: pot,
            progress: progress,
            subject: subject,
            streak: streak,
            phaseName: phaseName,
            plantImagePath: plantImagePath
        )
    }
}

struct PomodoroWidgetView: View {
    var entry: PomodoroEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if family == .systemMedium {
                MediumWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        }
        .widgetURL(URL(string: "upeaconnect://pomodoro"))
        .widgetBackground()
    }
}

// VISTA PEQUEÑA (2x2)
struct SmallWidgetView: View {
    var entry: PomodoroEntry

    var body: some View {
        VStack(spacing: 4) {
            // Cabecera: Racha y Badge UPEA
            HStack {
                HStack(spacing: 2) {
                    Text("🔥")
                        .font(.system(size: 10))
                    Text("\(entry.streak) D")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color.orange)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(6)

                Spacer()

                Text("UPEA")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.80, blue: 0.01))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.35, green: 0.80, blue: 0.01).opacity(0.15))
                    .cornerRadius(4)
            }

            Spacer(minLength: 0)

            // Planta en su maceta
            PlantGraphicView(
                species: entry.species,
                pot: entry.pot,
                progress: entry.progress,
                plantImagePath: entry.plantImagePath,
                size: 70
            )

            Spacer(minLength: 0)

            // Barra de progreso y porcentaje
            VStack(spacing: 2) {
                HStack {
                    Text(entry.phaseName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(entry.progress * 100))%")
                        .font(.system(size: 8.5, weight: .black))
                        .foregroundColor(Color(red: 0.35, green: 0.80, blue: 0.01))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.35, green: 0.80, blue: 0.01))
                            .frame(width: max(0, min(geo.size.width * CGFloat(entry.progress), geo.size.width)), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(11)
    }
}

// VISTA MEDIANA (4x2)
struct MediumWidgetView: View {
    var entry: PomodoroEntry

    var body: some View {
        HStack(spacing: 12) {
            // Cuadro botánico izquierdo
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.35, green: 0.80, blue: 0.01).opacity(0.25), Color.white.opacity(0.02)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                PlantGraphicView(
                    species: entry.species,
                    pot: entry.pot,
                    progress: entry.progress,
                    plantImagePath: entry.plantImagePath,
                    size: 92
                )
            }
            .frame(width: 105, height: 110)

            // Panel derecho de estadísticas
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(entry.subject)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 10))
                        Text("\(entry.streak) DÍAS")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Color.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                }

                Text("🌱 \(getSpeciesDisplayName(entry.species)) • \(entry.phaseName)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Barra de Progreso
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Crecimiento")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(entry.progress * 100))%")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.35, green: 0.80, blue: 0.01))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 5)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.35, green: 0.80, blue: 0.01))
                                .frame(width: max(0, min(geo.size.width * CGFloat(entry.progress), geo.size.width)), height: 5)
                        }
                    }
                    .frame(height: 5)
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text("Toca para estudiar y regar")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(.vertical, 4)
        }
        .padding(12)
    }

    private func getSpeciesDisplayName(_ id: String) -> String {
        switch id {
        case "sp_rose": return "Rosa Roja"
        case "sp_sakura": return "Cerezo Sakura"
        case "sp_oak": fallthrough
        default: return "Roble Clásico"
        }
    }
}

// COMPONENTE VISUAL DE LA PLANTA Y MACETA
struct PlantGraphicView: View {
    let species: String
    let pot: String
    let progress: Double
    let plantImagePath: String?
    let size: CGFloat

    var phase: Int {
        if progress >= 0.75 { return 4 }
        if progress >= 0.50 { return 3 }
        if progress >= 0.25 { return 2 }
        return 1
    }

    var plantImageName: String {
        switch species {
        case "sp_rose":
            switch phase {
            case 1: return "fase1_rosa_brote"
            case 2: return "fase2_rosa_vastago"
            case 3: return "fase3_rosa_capullo"
            default: return "fase4_rosa_floripondio"
            }
        case "sp_sakura":
            switch phase {
            case 1: return "fase1_sakura_brote"
            case 2: return "fase2_sakura_rama"
            case 3: return "fase3_sakura_capullo"
            default: return "fase4_sakura_plena"
            }
        case "sp_oak": fallthrough
        default:
            switch phase {
            case 1: return "fase1_plantula"
            case 2: return "fase2_planta_joven"
            case 3: return "fase3_planta_madura"
            default: return "fase4_planta_frondosa"
            }
        }
    }

    var potImageName: String {
        switch pot {
        case "pot_gold": return "maceta_dorada"
        case "pot_japanese": return "maceta_japonesa"
        case "pot_volcanic": return "maceta_volcanica"
        case "pot_default": fallthrough
        default: return "maceta_normal"
        }
    }

    var body: some View {
        Group {
            // Prioridad 1: Imagen renderizada por Flutter desde la app
            if let path = plantImagePath, FileManager.default.fileExists(atPath: path), let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                // Prioridad 2: Dibujado de Maceta + Planta desde recursos del bundle
                ZStack(alignment: .bottom) {
                    if let potImg = loadBundleImage(named: potImageName) {
                        Image(uiImage: potImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.60, height: size * 0.38)
                            .offset(y: 2)
                    } else {
                        Text("🪴")
                            .font(.system(size: size * 0.35))
                    }

                    if let plantImg = loadBundleImage(named: plantImageName) {
                        Image(uiImage: plantImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.80, height: size * 0.72)
                            .offset(y: -size * 0.22)
                    } else {
                        Text("🌿")
                            .font(.system(size: size * 0.50))
                            .offset(y: -size * 0.18)
                    }
                }
                .frame(width: size, height: size)
            }
        }
    }

    private func loadBundleImage(named: String) -> UIImage? {
        // 1. Probar en Bundle.main (bundle del widget)
        if let path = Bundle.main.path(forResource: named, ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        // 2. Probar acceso directo por bundleURL
        let directUrl = Bundle.main.bundleURL.appendingPathComponent("\(named).png")
        if FileManager.default.fileExists(atPath: directUrl.path) {
            return UIImage(contentsOfFile: directUrl.path)
        }
        // 3. Probar UIImage(named:in:with:)
        if let img = UIImage(named: named, in: Bundle.main, with: nil) {
            return img
        }
        return nil
    }
}

// EXTENSIONES COMPATIBLES CON iOS 15, 16, 17 Y 18
extension View {
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.15, blue: 0.22), Color(red: 0.06, green: 0.09, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            return self.background(
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.15, blue: 0.22), Color(red: 0.06, green: 0.09, blue: 0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

extension WidgetConfiguration {
    func disableMarginsIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

struct PomodoroWidget: Widget {
    let kind: String = "PomodoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroTimelineProvider()) { entry in
            PomodoroWidgetView(entry: entry)
        }
        .configurationDisplayName("Planta de Enfoque UPEA")
        .description("Sigue el crecimiento de tu planta Pomodoro y cuida tu racha de estudio diaria.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .disableMarginsIfAvailable()
    }
}
