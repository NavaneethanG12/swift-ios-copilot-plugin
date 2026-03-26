---
name: storekit
description: >
  Implement in-app purchases with StoreKit 2 — products, transactions,
  subscriptions, receipt validation, offer codes.
argument-hint: "[purchase type, StoreKit issue, or subscription question]"
user-invocable: true
---

# StoreKit 2

## Products

```swift
let products = try await Product.products(for: ["com.app.premium", "com.app.coins100"])
// product.displayName, .displayPrice, .type (.consumable, .nonConsumable, .autoRenewable)
```

## Purchase Flow

```swift
let result = try await product.purchase()
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    // Deliver content
    await transaction.finish()
case .userCancelled: break
case .pending: break  // Ask-to-Buy
@unknown default: break
}

func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified: throw StoreError.unverified
    case .verified(let safe): return safe
    }
}
```

## Transaction Listener

```swift
// Start at app launch — handles out-of-app transactions
Task.detached {
    for await result in Transaction.updates {
        guard let tx = try? checkVerified(result) else { continue }
        await deliverContent(for: tx)
        await tx.finish()
    }
}
```

## Subscriptions

```swift
// Check entitlement
for await result in Transaction.currentEntitlements {
    if let tx = try? checkVerified(result), tx.productType == .autoRenewable {
        // User has active subscription
    }
}
// Subscription status: product.subscription?.status
```

## Checklist

- [ ] `Transaction.updates` listener started at app launch
- [ ] All transactions verified before delivering content
- [ ] Transactions finished after delivery
- [ ] Subscription status checked on app foreground
- [ ] StoreKit Testing in Xcode for development
- [ ] Server-side validation for high-value purchases
