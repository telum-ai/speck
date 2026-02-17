---
name: revenuecat-integration
description: Load when integrating RevenueCat for in-app purchases and subscriptions. Applies when implementing iOS/Android subscriptions, entitlement checking, or purchase webhooks in React Native/Flutter.
---


## When This Rule Applies

Apply when implementing subscriptions or in-app purchases in React Native or Flutter apps.

---

## Platform Setup

### React Native Installation

```bash
npm install react-native-purchases
```

**Android**: Set launch mode to prevent purchase interruption:

```xml
<!-- AndroidManifest.xml -->
<activity android:name=".MainActivity" android:launchMode="standard" />
```

**iOS**: Enable In-App Purchase capability in Xcode.

### Initialization

```typescript
import Purchases from 'react-native-purchases';
import { Platform } from 'react-native';

useEffect(() => {
  Purchases.setLogLevel(Purchases.LOG_LEVEL.DEBUG);
  
  if (Platform.OS === 'ios') {
    Purchases.configure({ apiKey: 'ios_api_key' });
  } else {
    Purchases.configure({ apiKey: 'android_api_key' });
  }
}, []);
```

### Flutter Initialization

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

await Purchases.setLogLevel(LogLevel.debug);

if (defaultTargetPlatform == TargetPlatform.iOS) {
  await Purchases.configure(PurchasesConfiguration('ios_key'));
} else {
  await Purchases.configure(PurchasesConfiguration('android_key'));
}
```

---

## Entitlement Checking

### React Native Hook

```typescript
export function useSubscription() {
  const [isSubscribed, setIsSubscribed] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkSubscription();
  }, []);

  const checkSubscription = async () => {
    try {
      setLoading(true);
      const info = await Purchases.getCustomerInfo();
      // Check for active entitlement
      setIsSubscribed(!!info.entitlements.active['premium']);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return { isSubscribed, loading, refresh: checkSubscription };
}
```

### Flutter

```dart
Future<bool> isPremium() async {
  final info = await Purchases.getCustomerInfo();
  return info.entitlements.active.containsKey('premium');
}
```

### Backend Verification (Security-Critical Operations)

```typescript
// Always verify on backend for sensitive operations
const response = await fetch(
  `https://api.revenuecat.com/v1/subscribers/${userId}`,
  { headers: { Authorization: `Bearer ${REVENUECAT_API_KEY}` } }
);
const data = await response.json();
const isActive = Object.keys(data.subscriber.entitlements.active).length > 0;
```

---

## Making Purchases

### Display Paywall

```typescript
export function Paywall() {
  const [offerings, setOfferings] = useState(null);
  const [purchasing, setPurchasing] = useState(false);

  useEffect(() => {
    loadOfferings();
  }, []);

  const loadOfferings = async () => {
    const { current } = await Purchases.getOfferings();
    setOfferings(current);
  };

  const purchase = async (pkg) => {
    try {
      setPurchasing(true);
      const { customerInfo } = await Purchases.purchasePackage(pkg);
      
      if (customerInfo.entitlements.active['premium']) {
        Alert.alert('Success', 'Subscription activated!');
      }
    } catch (error) {
      if (!error.userCancelled) {
        Alert.alert('Error', error.message);
      }
    } finally {
      setPurchasing(false);
    }
  };

  if (!offerings) return <ActivityIndicator />;

  return (
    <View>
      <Button
        title={`Monthly - ${offerings.monthly?.localizedPriceString}`}
        onPress={() => purchase(offerings.monthly)}
        disabled={purchasing}
      />
      <Button
        title={`Annual - ${offerings.annual?.localizedPriceString}`}
        onPress={() => purchase(offerings.annual)}
        disabled={purchasing}
      />
    </View>
  );
}
```

---

## Webhook Handling

### Express.js Handler

```typescript
app.post('/webhooks/revenuecat', async (req, res) => {
  // Validate auth header
  if (req.headers.authorization !== process.env.REVENUECAT_WEBHOOK_SECRET) {
    return res.status(401).send('Unauthorized');
  }

  const { type, app_user_id } = req.body;

  // Query RevenueCat for authoritative state
  const subscriber = await fetchSubscriber(app_user_id);
  const isActive = Object.keys(subscriber.entitlements.active).length > 0;

  // Update your database
  await db.users.update({
    where: { id: app_user_id },
    data: { isPremium: isActive },
  });

  res.status(200).send('OK');
});
```

### Key Webhook Events

| Event | When | Action |
|-------|------|--------|
| `INITIAL_PURCHASE` | First subscription | Provision access |
| `RENEWAL` | Auto-renewed | Log retention |
| `BILLING_ISSUE_DETECTED` | Payment failed | Prompt to update card |
| `SUBSCRIPTION_EXPIRED` | Cancelled + period ended | Revoke access |
| `CANCELLATION` | User cancelled (still active) | Show retention offer |

### Idempotency

Webhooks may be delivered multiple times. Track processed events:

```typescript
const processed = await db.webhookEvents.findOne({ id: event.id });
if (processed) return res.status(200).send('Already processed');

await handleWebhook(event);
await db.webhookEvents.create({ id: event.id });
```

---

## Sandbox Testing

### Two Testing Approaches

| Approach | Use Case | Limitations |
|----------|----------|-------------|
| **RevenueCat Test Store** | Early dev, no Apple/Google setup | No platform-specific features |
| **Platform Sandboxes** | Pre-launch, full integration | Metadata may not match production |

### Testing Workflow

1. **Development**: Use Test Store for rapid iteration
2. **Pre-Launch**: Switch to platform sandboxes for full integration testing
3. **Never deploy with Test Store API keys**

### Sandbox Access Control

In RevenueCat Dashboard → Project Settings:

- `Anybody`: All sandbox purchases grant entitlements
- `Allowed App User IDs only`: Whitelist specific test users
- `Nobody`: Track purchases without granting access

---

## Common Gotchas

### Android Launch Mode Causes Random Cancellations

When users are redirected to banking apps for payment verification, wrong launch mode cancels purchases:

```xml
<!-- MUST be standard or singleTop -->
<activity android:launchMode="standard" />
```

### Entitlement Detachment is Retroactive

Detaching an entitlement from a product removes access for ALL existing customers instantly. Be careful when modifying entitlement-product mappings.

### Product ID Naming Convention

Use platform suffixes to avoid confusion:

```
monthly_ios, yearly_ios
monthly_android, yearly_android
```

### Billing Grace Period (iOS)

Users keep access for ~16 days after failed payment. Check `grace_period_expires_date` in API response.

### Webhook Event Ordering

Events may arrive out of order. Always query RevenueCat API for current state rather than building state from events.

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Check subscription | `customerInfo.entitlements.active['premium']` |
| Make purchase | `Purchases.purchasePackage(pkg)` |
| Load offerings | `Purchases.getOfferings()` |
| Backend verification | GET `/v1/subscribers/{id}` |
| Webhook auth | Check `Authorization` header |
| Test Store → Sandbox | Change API key before launch |

## References

- [RevenueCat React Native](https://www.revenuecat.com/docs/getting-started/installation/reactnative)
- [RevenueCat Flutter](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [Entitlements](https://www.revenuecat.com/docs/getting-started/entitlements)
- [Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)

