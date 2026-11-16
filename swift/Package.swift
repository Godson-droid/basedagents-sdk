// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BasedAgentsSDK",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "BasedAgentsSDK", targets: ["BasedAgentsSDK"]),
    ],
    targets: [
        .target(name: "BasedAgentsSDK"),
        .testTarget(
            name: "BasedAgentsSDKTests",
            dependencies: ["BasedAgentsSDK"],
            resources: [
                .copy("Resources/agent_bot.json"),
                .copy("Resources/agent_jarvis.json"),
                .copy("Resources/agent_reputation_jarvis.json"),
                .copy("Resources/agent_wallet_jarvis.json"),
                .copy("Resources/agents_search_jarvis.json"),
                .copy("Resources/chain_latest.json"),
                .copy("Resources/error_task_not_found.json"),
                .copy("Resources/health.json"),
                .copy("Resources/service_descriptor.json"),
                .copy("Resources/status.json"),
                .copy("Resources/task_detail_observatory.json"),
                .copy("Resources/task_detail_sdk.json"),
                .copy("Resources/task_detail_settled.json"),
                .copy("Resources/task_payment_sdk.json"),
                .copy("Resources/task_payment_settled.json"),
                .copy("Resources/task_receipt_sdk.json"),
                .copy("Resources/task_receipts_sdk.json"),
                .copy("Resources/task_submission_sdk.json"),
                .copy("Resources/tasks_category_code.json"),
                .copy("Resources/tasks_open.json"),
                .copy("Resources/tasks_open_page.json"),
                .copy("Resources/tasks_settled.json"),
                .copy("Resources/agent_skills_object.json"),
                .copy("Resources/agent_reputation_fractional.json"),
                .copy("Resources/task_creator_wallet.json"),
                .copy("Resources/chain_range.json"),
                .copy("Resources/chain_entry.json")
            ]
        ),
    ]
)
