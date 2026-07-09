-- Backfill audit actor for records created before created_by was populated.
-- Uses account owner (user_id on domain rows) as the recorded-by user.

UPDATE purchases p
SET created_by = p.user_id
WHERE p.created_by IS NULL;

UPDATE purchase_items pi
SET created_by = p.user_id
FROM purchases p
WHERE pi.purchase_id = p.id
  AND pi.created_by IS NULL;

UPDATE supplier_payments sp
SET created_by = sp.user_id
WHERE sp.created_by IS NULL;

UPDATE suppliers s
SET created_by = s.user_id
WHERE s.created_by IS NULL;
