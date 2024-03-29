//
import SwiftUI
import QMobileAPI

struct MetadataView: View {
    @ObservedObject var request: ActionRequest
    @State var debug = false
    @State var tapCount = 0

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State var since = ""

    var body: some View {
        HStack {
            ForEach(
                [("clock", "\(timeSince(request.lastDate ?? request.creationDate))", Color.primary),
                 ("key.icloud", debug ? "\(request.recordSummary)": "", Color.secondary),
                 ("arrow.counterclockwise", debug ? "\(request.tryCount)": "", Color.secondary)
                ], id: \.0) { data in
                Group {
                    if !data.1.isEmpty {
                        switch data.0 {
                        case "clock":
                            Text(since.isEmpty ? data.1: since)
                                .onReceive(timer) { _ in
                                    since = "\(timeSince(request.creationDate))"
                                }
                        default:
                            Image(systemName: data.0)
                            Text(data.1)
                        }
                    }
                }
                .foregroundColor(data.2)
            }.onTapGesture {
                tapCount+=1
                debug = (tapCount % 10) == 0
            }
        }
    }
}

#if DEBUG
struct MetadataView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MetadataView(request: ActionRequest.examples[0])
            MetadataView(request: ActionRequest.examples[1])
            MetadataView(request: ActionRequest.examples[2])
        }.previewLayout(.fixed(width: 300, height: 30))
    }
}
#endif

func timeSince(_ date: Date?) -> String {
    guard let date = date else {
        return ""
    }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    let now = Date()
    if Calendar.current.isDate(date, equalTo: now, toGranularity: .second) {
        formatter.dateTimeStyle = .named
    }
    return formatter.localizedString(for: date, relativeTo: now)
}
