# Rollback Plan — FEAT-003

1. Disable `shipment_email_enabled` feature flag
2. Revert notification module commits
3. Verify orders ship without email side effects
