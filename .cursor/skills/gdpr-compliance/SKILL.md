---
name: gdpr-compliance
description: Load when implementing GDPR compliance for applications processing EU personal data. Applies when building consent management, data export, right to erasure, or audit logging.
---


## Key GDPR Principles

| Principle | Implementation |
|-----------|----------------|
| **Lawfulness** | Consent or legitimate interest documented |
| **Purpose Limitation** | Only collect for stated purposes |
| **Data Minimization** | Collect only what's necessary |
| **Accuracy** | Allow users to correct data |
| **Storage Limitation** | Delete when no longer needed |
| **Integrity** | Encrypt, access control |
| **Accountability** | Audit logs, DPO |

---

## Consent Management

### Consent Model

```sql
CREATE TABLE consents (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  purpose VARCHAR(100) NOT NULL,  -- 'marketing', 'analytics', 'personalization'
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ,
  withdrawn_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for quick consent checks
CREATE INDEX idx_consents_user_purpose ON consents(user_id, purpose);
```

### Consent Check

```typescript
async function hasConsent(userId: string, purpose: string): Promise<boolean> {
  const consent = await db.consents.findFirst({
    where: { 
      user_id: userId, 
      purpose,
      granted: true,
      withdrawn_at: null,
    },
    orderBy: { created_at: 'desc' },
  });
  
  return !!consent;
}

// Usage
if (await hasConsent(userId, 'marketing')) {
  await sendMarketingEmail(userId);
}
```

### Consent Banner

```typescript
// Required elements:
// 1. Clear explanation of each purpose
// 2. Granular opt-in (not bundled)
// 3. Easy withdraw mechanism
// 4. No pre-checked boxes

interface ConsentPreferences {
  necessary: true;  // Can't be disabled
  analytics: boolean;
  marketing: boolean;
  personalization: boolean;
}
```

---

## Data Subject Rights

### Right to Access (Data Export)

```typescript
async function exportUserData(userId: string): Promise<UserDataExport> {
  const [user, orders, consents, activityLog] = await Promise.all([
    db.users.findUnique({ where: { id: userId } }),
    db.orders.findMany({ where: { user_id: userId } }),
    db.consents.findMany({ where: { user_id: userId } }),
    db.activity_logs.findMany({ where: { user_id: userId } }),
  ]);
  
  return {
    personal_info: {
      email: user.email,
      name: user.name,
      created_at: user.created_at,
    },
    orders: orders.map(o => ({
      id: o.id,
      total: o.total,
      created_at: o.created_at,
    })),
    consent_history: consents,
    activity_log: activityLog,
    exported_at: new Date().toISOString(),
  };
}

// API endpoint
app.get('/api/me/data-export', async (req, res) => {
  const data = await exportUserData(req.user.id);
  res.json(data);
});
```

### Right to Erasure (Data Deletion)

```typescript
async function deleteUserData(userId: string): Promise<void> {
  // 1. Delete from all tables
  await db.$transaction([
    db.activity_logs.deleteMany({ where: { user_id: userId } }),
    db.consents.deleteMany({ where: { user_id: userId } }),
    db.sessions.deleteMany({ where: { user_id: userId } }),
    // Keep orders for legal reasons, but anonymize
    db.orders.updateMany({
      where: { user_id: userId },
      data: { 
        user_id: null,
        customer_email: 'deleted@anonymized.com',
        customer_name: 'Deleted User',
      },
    }),
    db.users.delete({ where: { id: userId } }),
  ]);
  
  // 2. Delete from external services
  await Promise.all([
    analytics.deleteUser(userId),
    emailService.deleteContact(userId),
    storage.deleteUserFiles(userId),
  ]);
  
  // 3. Log deletion for compliance
  await auditLog.create({
    action: 'USER_DATA_DELETED',
    subject_id: userId,
    timestamp: new Date(),
  });
}
```

### Right to Rectification

```typescript
app.patch('/api/me', async (req, res) => {
  const { name, email } = req.body;
  
  await db.users.update({
    where: { id: req.user.id },
    data: { name, email },
  });
  
  await auditLog.create({
    action: 'USER_DATA_UPDATED',
    user_id: req.user.id,
    changes: { name, email },
  });
  
  res.json({ success: true });
});
```

---

## Data Minimization

### Collect Only What's Needed

```typescript
// BAD: Collecting unnecessary data
interface UserRegistration {
  email: string;
  password: string;
  phone: string;      // Not needed for email-based product
  birthdate: string;  // Not needed
  address: string;    // Not needed
}

// GOOD: Minimum viable data
interface UserRegistration {
  email: string;
  password: string;
}
```

### Retention Policies

```sql
-- Auto-delete old activity logs
DELETE FROM activity_logs WHERE created_at < NOW() - INTERVAL '2 years';

-- Anonymize old orders (keep for accounting, anonymize PII)
UPDATE orders 
SET customer_email = 'anonymized@deleted.com',
    customer_name = 'Anonymized'
WHERE created_at < NOW() - INTERVAL '7 years';
```

---

## Privacy by Design

### Pseudonymization

```typescript
// Don't use email as ID across systems
// Use opaque user ID instead

interface AnalyticsEvent {
  user_id: string;  // UUID, not email
  event: string;
  properties: Record<string, unknown>;
}

// Analytics service never sees email
analytics.track({
  user_id: user.id,  // Not user.email
  event: 'purchase_completed',
  properties: { amount: 99 },
});
```

### Encryption at Rest

```typescript
// Encrypt sensitive fields before storage
import { encrypt, decrypt } from './crypto';

await db.users.create({
  data: {
    email: user.email,  // Plain for login lookup
    phone_encrypted: encrypt(user.phone),  // Encrypted
    ssn_encrypted: encrypt(user.ssn),       // Encrypted
  },
});
```

---

## Audit Logging

### Audit Log Schema

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  actor_id UUID,                    -- Who performed action
  action VARCHAR(100) NOT NULL,     -- 'USER_CREATED', 'DATA_EXPORTED', etc.
  resource_type VARCHAR(50),        -- 'user', 'order', etc.
  resource_id UUID,
  changes JSONB,                    -- Before/after values
  ip_address INET,
  user_agent TEXT
);
```

### Log Sensitive Operations

```typescript
async function auditLog(params: {
  actor_id: string;
  action: string;
  resource_type?: string;
  resource_id?: string;
  changes?: Record<string, unknown>;
  req?: Request;
}) {
  await db.audit_logs.create({
    data: {
      ...params,
      ip_address: params.req?.ip,
      user_agent: params.req?.headers['user-agent'],
    },
  });
}

// Usage
await auditLog({
  actor_id: adminUser.id,
  action: 'USER_DATA_ACCESSED',
  resource_type: 'user',
  resource_id: targetUser.id,
  req,
});
```

---

## Third-Party Data Processing

### Data Processing Agreement (DPA) Requirements

For each vendor that processes personal data:

1. ✓ Signed DPA in place
2. ✓ Sub-processor list maintained
3. ✓ EU data residency (or adequacy decision / SCCs)
4. ✓ Deletion obligations documented

### Vendor Checklist

| Service | Data Sent | DPA | Residency |
|---------|-----------|-----|-----------|
| Stripe | Email, name | ✓ | EU |
| Sentry | IP, user agent | ✓ | US (SCCs) |
| PostHog | User ID, events | ✓ | EU Cloud |

---

## Common Gotchas

### Cookie Banner ≠ GDPR Compliance
GDPR is much broader than cookies. Applies to all personal data processing.

### "Legitimate Interest" Isn't a Free Pass
Must document and balance against user rights. Users can still object.

### Backup Retention
Deleted data may persist in backups. Document retention and deletion procedures.

### Analytics Without Consent
Cookie-less analytics (PostHog, Plausible) can work without consent, but verify with legal.

### International Transfers
Post-Brexit UK needs separate analysis. US requires SCCs or alternative safeguards.

---

## Quick Reference

| Requirement | Implementation |
|-------------|----------------|
| Consent | Granular opt-in, easy withdraw |
| Data export | JSON export endpoint |
| Data deletion | Transaction + external services |
| Audit log | All sensitive operations logged |
| Retention | Auto-delete old data |
| Encryption | Encrypt sensitive fields at rest |

## References

- [GDPR Text](https://gdpr-info.eu/)
- [ICO Guidance (UK)](https://ico.org.uk/for-organisations/guide-to-data-protection/)
- [CNIL Guidance (France)](https://www.cnil.fr/en)
