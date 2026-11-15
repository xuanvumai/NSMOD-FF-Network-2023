
import SwiftUI
import Network
import Combine

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "com.xuanvumai.nsmodffnetwork.monitor"
    )

    @Published var isConnected = false
    @Published var connectionType = "Đang kiểm tra..."
    @Published var isExpensive = false
    @Published var isConstrained = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained

                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "4G / 5G"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = "Ethernet"
                } else {
                    self.connectionType = "Không xác định"
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
                VStack(spacing: 20) {

                    VStack(spacing: 10) {
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

                    VStack(spacing: 12) {
                        Image(
                            systemName: network.isConnected
                            ? "checkmark.circle.fill"
                            : "xmark.circle.fill"
                        )
                        .font(.system(size: 50))
                        .foregroundStyle(
                            network.isConnected ? .green : .red
                        )

                        Text(
                            network.isConnected
                            ? "Đã kết nối Internet"
                            : "Chưa có kết nối Internet"
                        )
                        .font(.headline)

                        Text("Trạng thái được cập nhật tự động")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(25)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )

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

                    VStack(spacing: 8) {
                        Text("NSMOD FF NETWORK")
                            .font(.headline)

                        Text(
                            "Công cụ theo dõi trạng thái kết nối mạng. "
                            + "Không can thiệp vào máy chủ trò chơi "
                            + "hoặc đảm bảo giảm ping."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)
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
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
    }
}
