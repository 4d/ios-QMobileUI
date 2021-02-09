//
import SwiftUI
import QMobileAPI

struct MetadataView: View {
    let request: ActionRequest

    var body: some View {
        HStack {
            ForEach(
                [
                    ("clock", "\(timeSince(request.creationDate))", Color.primary),
                    ("arrow.counterclockwise", "\(request.tryCount)", Color.secondary),
                    ("tablecells", "\(request.tableName)", Color.primary)
                ], id: \.0) { data in
                Group {
                    Image(systemName: data.0)
                    Text(data.1)
                }
                .foregroundColor(data.2)
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
    return formatter.localizedString(for: date, relativeTo: Date())
}
