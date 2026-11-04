--liquibase formatted sql
--changeset voxprep:b8-p1-0001-purchase-ledger
SET ROLE voxprep_owner;
CREATE TABLE app.store_purchase (
  id uuid PRIMARY KEY,
  provider varchar(16) NOT NULL CHECK (provider IN ('GOOGLE_PLAY','APP_STORE')),
  product_id varchar(100) NOT NULL,
  transaction_sha256 varchar(64) NOT NULL CHECK (transaction_sha256 ~ '^[0-9a-f]{64}$'),
  purchase_state varchar(16) NOT NULL CHECK (purchase_state IN ('GRANTED','PENDING','REVOKED')),
  environment varchar(16) NOT NULL CHECK (environment IN ('PRODUCTION','SANDBOX','SIMULATED')),
  verified_at timestamptz,
  updated_at timestamptz NOT NULL,
  UNIQUE (provider, product_id, transaction_sha256),
  CHECK ((purchase_state <> 'GRANTED') OR verified_at IS NOT NULL)
);
CREATE TABLE app.store_purchase_claim (
  purchase_id uuid NOT NULL REFERENCES app.store_purchase(id) ON DELETE RESTRICT,
  installation_id uuid NOT NULL REFERENCES app.installation(installation_id) ON DELETE RESTRICT,
  claimed_at timestamptz NOT NULL,
  PRIMARY KEY (purchase_id, installation_id)
);
CREATE INDEX ix_store_purchase_claim_installation ON app.store_purchase_claim(installation_id);
CREATE TABLE app.purchase_verify_event (
  installation_id uuid NOT NULL REFERENCES app.installation(installation_id) ON DELETE RESTRICT,
  event_id varchar(160) NOT NULL,
  semantic_sha256 varchar(64) NOT NULL CHECK (semantic_sha256 ~ '^[0-9a-f]{64}$'),
  recorded_at timestamptz NOT NULL,
  PRIMARY KEY (installation_id, event_id)
);
RESET ROLE;
--rollback SET ROLE voxprep_owner;
--rollback DROP TABLE app.purchase_verify_event;
--rollback DROP TABLE app.store_purchase_claim;
--rollback DROP TABLE app.store_purchase;
--rollback RESET ROLE;
