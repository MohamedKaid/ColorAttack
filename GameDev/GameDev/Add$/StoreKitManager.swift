//
//  StoreKitManager.swift
//  GameDev
//
//  Manages all In-App Purchases:
//    - com.example.ColorAttack.noads     ($1.99) — removes all ads
//    - com.example.ColorAttack.premium   ($2.99) — removes ads + unlocks Chaos & Sequence unlimited
//

import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product IDs
    static let noAdsID    = "com.example.ColorAttack.noads"
    static let premiumID  = "com.example.ColorAttack.premium"

    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var hasNoAds: Bool = false
    @Published private(set) var hasPremium: Bool = false

    /// True if ads should be hidden (either IAP purchased)
    var adsRemoved: Bool { hasNoAds || hasPremium }

    /// True if Chaos & Sequence are fully unlocked
    var premiumUnlocked: Bool { hasPremium }

    // MARK: - Private
    private var transactionListener: Task<Void, Never>?

    // MARK: - Init / Deinit
    init() {
        transactionListener = listenForTransactions()
        Task { await loadProductsAndEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products & Restore Entitlements

    func loadProductsAndEntitlements() async {
        await fetchProducts()
        await restoreEntitlements()
    }

    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.noAdsID, Self.premiumID])
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            print("StoreKit: Failed to fetch products — \(error)")
        }
    }

    func restoreEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result {
                apply(transaction: tx)
            }
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            if case .verified(let tx) = verification {
                apply(transaction: tx)
                await tx.finish()
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Convenience Purchase by ID

    func purchaseNoAds() async {
        guard let product = products.first(where: { $0.id == Self.noAdsID }) else { return }
        try? await purchase(product)
    }

    func purchasePremium() async {
        guard let product = products.first(where: { $0.id == Self.premiumID }) else { return }
        try? await purchase(product)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await MainActor.run { apply(transaction: tx) }
                    await tx.finish()
                }
            }
        }
    }

    // MARK: - Apply

    private func apply(transaction tx: Transaction) {
        guard tx.revocationDate == nil else {
            // Refunded — revoke
            if tx.productID == Self.noAdsID   { hasNoAds   = false }
            if tx.productID == Self.premiumID  { hasPremium = false }
            return
        }
        switch tx.productID {
        case Self.noAdsID:   hasNoAds   = true
        case Self.premiumID: hasPremium = true; hasNoAds = true
        default: break
        }
    }

    // MARK: - Formatted Prices

    var noAdsPrice: String {
        products.first(where: { $0.id == Self.noAdsID })?.displayPrice ?? "$1.99"
    }

    var premiumPrice: String {
        products.first(where: { $0.id == Self.premiumID })?.displayPrice ?? "$2.99"
    }
}
