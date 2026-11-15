
import SwiftUI
import Network

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "com.xuanvumai.nsmodffnetwork.monitor"
    )

    @Published var isConnected = false
    @Published var connectionType = "Đang kiểm tra"
    @Published var isExpensive = false
    @Published var isConstrained = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "Di động"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "Ethernet"
                } else {
                    self?.connectionType = "Không xác định"
                }
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

struct ContentView: View {
    @StateObject private var network = NetworkMonitor()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Image(systemName: "network")
                            .font(.system(size: 55))
                            .foregroundStyle(.blue)

                        Text("NSMOD FF NETWORK")
                            .font(.title2.bold())

                        Text("NETWORK MONITOR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 25)

                    VStack(spacing: 14) {
                        Image(
                            systemName: network.isConnected
                            ? "checkmark.circle.fill"
                            : "xmark.circle.fill"
                        )
                        .font(.system(size: 48))
                        .foregroundStyle(
                            network.isConnected ? .green : .red
                        )

                        Text(
                            network.isConnected
                            ? "Đã kết nối Internet"
                            : "Chưa có kết nối Internet"
                        )
                        .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(25)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    infoCard(
                        title: "Loại kết nối",
                        value: network.connectionType,
                        icon: "antenna.radiowaves.left.and.right"
                    )

                    infoCard(
                        title: "Mạng tiêu tốn dữ liệu",
                        value: network.isExpensive ? "Có" : "Không",
                        icon: "chart.bar"
                    )

                    infoCard(
                        title: "Chế độ dữ liệu hạn chế",
                        value: network.isConstrained ? "Có" : "Không",
                        icon: "speedometer"
                    )

                    Text(
                        "Ứng dụng theo dõi trạng thái mạng theo thời gian thực. "
                        + "Không đảm bảo thay đổi hoặc giảm độ trễ máy chủ."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("NSMOD NETWORK")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}
