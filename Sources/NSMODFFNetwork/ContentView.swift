
import SwiftUI
import Network

@MainActor
final class NetworkMonitorModel: ObservableObject {
    @Published var ping: Int?
    @Published var average = 0
    @Published var maximum = 0
    @Published var networkName = "Đang kiểm tra..."
    @Published var connectionStatus = "Chưa đo"
    @Published var isMeasuring = false
    @Published var history: [Int] = []

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "nsmod.network")
    private var task: Task<Void, Never>?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }

                if path.status != .satisfied {
                    self.networkName = "Offline"
                } else if path.usesInterfaceType(.wifi) {
                    self.networkName = "Wi-Fi"
                } else if path.usesInterfaceType(.cellular) {
                    self.networkName = "4G / 5G"
                } else {
                    self.networkName = "Mạng khác"
                }
            }
        }

        monitor.start(queue: queue)
    }

    func start() {
        guard !isMeasuring else { return }

        isMeasuring = true
        history.removeAll()
        maximum = 0
        average = 0

        task = Task {
            while !Task.isCancelled {
                let result = await measurePing()

                if Task.isCancelled { break }

                if let result {
                    ping = result
                    history.append(result)

                    if history.count > 60 {
                        history.removeFirst()
                    }

                    average = history.reduce(0, +) / history.count
                    maximum = max(maximum, result)

                    if result < 60 {
                        connectionStatus = "Kết nối tốt"
                    } else if result < 100 {
                        connectionStatus = "Kết nối trung bình"
                    } else {
                        connectionStatus = "Kết nối chậm"
                    }
                } else {
                    ping = nil
                    connectionStatus = "Không kết nối được"
                }

                try? await Task.sleep(
                    nanoseconds: 2_000_000_000
                )
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isMeasuring = false
        connectionStatus = "Đã dừng đo"
    }

    private func measurePing() async -> Int? {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host("1.1.1.1"),
                port: NWEndpoint.Port(rawValue: 443)!,
                using: .tcp
            )

            let start = DispatchTime.now().uptimeNanoseconds
            let lock = NSLock()
            var finished = false

            func finish(_ result: Int?) {
                lock.lock()
                let shouldFinish = !finished
                finished = true
                lock.unlock()

                guard shouldFinish else { return }

                connection.stateUpdateHandler = nil
                connection.cancel()
                continuation.resume(returning: result)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed =
                        DispatchTime.now().uptimeNanoseconds - start

                    finish(Int(elapsed / 1_000_000))

                case .failed:
                    finish(nil)

                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(
                deadline: .now() + 5
            ) {
                finish(nil)
            }
        }
    }

    deinit {
        task?.cancel()
        monitor.cancel()
    }
}

struct ContentView: View {
    @StateObject private var model = NetworkMonitorModel()

    private var pingColor: Color {
        guard let ping = model.ping else {
            return .gray
        }

        if ping < 60 {
            return .green
        } else if ping < 100 {
            return .orange
        } else {
            return .red
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    VStack(spacing: 8) {
                        Text("NSMOD FF NETWORK")
                            .font(.title.bold())

                        Text("BARBOSA TECH • 2023")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Text("NETWORK LATENCY")

                        Text(
                            model.ping.map {
                                "\($0) ms"
                            } ?? "-- ms"
                        )
                        .font(.system(size: 55, weight: .bold))
                        .foregroundStyle(pingColor)

                        Text(model.connectionStatus)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(25)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 22)
                    )

                    HStack(spacing: 12) {
                        statCard(
                            "PING TRUNG BÌNH",
                            "\(model.average) ms"
                        )

                        statCard(
                            "PING CAO NHẤT",
                            "\(model.maximum) ms"
                        )
                    }

                    VStack(spacing: 15) {
                        HStack {
                            Label(
                                "Kết nối mạng",
                                systemImage: "wifi"
                            )

                            Spacer()

                            Text(model.networkName)
                                .bold()
                        }

                        Divider()

                        HStack {
                            Text("Máy chủ đo")
                            Spacer()
                            Text("1.1.1.1:443")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            Text("Chu kỳ đo")
                            Spacer()
                            Text("2 giây")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 18)
                    )

                    Button {
                        if model.isMeasuring {
                            model.stop()
                        } else {
                            model.start()
                        }
                    } label: {
                        Text(
                            model.isMeasuring
                            ? "DỪNG KIỂM TRA"
                            : "BẮT ĐẦU TỐI ƯU"
                        )
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(
                            model.isMeasuring
                            ? Color.red : Color.blue,
                            in: RoundedRectangle(cornerRadius: 15)
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("LỊCH SỬ PING")
                            .font(.headline)

                        if model.history.isEmpty {
                            Text("Chưa có dữ liệu")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(
                            Array(
                                model.history.suffix(10)
                                    .reversed()
                                    .enumerated()
                            ),
                            id: \.offset
                        ) { index, value in
                            HStack {
                                Text("Lần \(index + 1)")
                                Spacer()
                                Text("\(value) ms")
                                    .bold()
                            }

                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 18)
                    )

                    Text(
                        "Đây là độ trễ thiết lập TCP tới máy chủ kiểm tra, không phải ping thực tế trong trận Free Fire. Ứng dụng không thể ép ping xuống 53ms hoặc điều khiển ghép trận."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .preferredColorScheme(.dark)
    }

    private func statCard(
        _ title: String,
        _ value: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}
