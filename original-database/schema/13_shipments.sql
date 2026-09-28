-- =============================================================
-- FILE: schema/13_shipments.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the shipments table
--              Tracks physical delivery of orders
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS shipments;

-- =============================================================
-- TABLE: shipments
--
-- WHY THIS TABLE EXISTS:
--   After payment is confirmed, the order needs to be physically
--   shipped. This table tracks the delivery journey from
--   warehouse to customer doorstep.
--
--   Separate from orders because:
--   - An order is a financial/commercial record
--   - A shipment is a logistics/operational record
--   - In future: one order could have multiple shipments
--     (items shipped from different warehouses)
--
-- RELATIONSHIPS:
--   shipments → orders  (one shipment per order, expandable to many)
-- =============================================================
CREATE TABLE shipments (

    shipment_id         BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which order is being shipped
    order_id            BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- COURIER INFORMATION
    -- tracking_number: given by the courier after pickup
    --   NULL = not dispatched yet
    -- courier_name: FedEx, BlueDart, Delhivery, DTDC etc.
    --   NULL = courier not assigned yet
    -- ---------------------------------------------------------
    tracking_number     VARCHAR(100)        NULL DEFAULT NULL,
    courier_name        VARCHAR(100)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- SHIPMENT STATUS
    -- Follows the physical journey of the package:
    -- preparing       = warehouse is packing the order
    -- dispatched      = courier has picked it up
    -- in_transit      = moving between courier hubs
    -- out_for_delivery = on the delivery vehicle today
    -- delivered       = customer received it
    -- returned        = customer refused or address wrong
    -- ---------------------------------------------------------
    status              ENUM(
                            'preparing',
                            'dispatched',
                            'in_transit',
                            'out_for_delivery',
                            'delivered',
                            'returned'
                        )                   NOT NULL DEFAULT 'preparing',

    -- Date shown to customer: "Estimated delivery by March 20"
    estimated_delivery  DATE                NULL DEFAULT NULL,

    -- Exact timestamp when customer received the package
    -- NULL = not yet delivered
    delivered_at        DATETIME            NULL DEFAULT NULL,

    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),

    -- FK to orders — restrict: don't delete orders with shipments
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Shipment tracking — one row per shipment per order';

-- =============================================================
-- INDEXES
-- =============================================================

-- Look up shipment for a specific order
CREATE INDEX idx_shipments_order_id
    ON shipments (order_id);

-- Track by courier tracking number (customer lookup)
CREATE INDEX idx_shipments_tracking
    ON shipments (tracking_number);

-- Filter by delivery status (operations dashboard)
CREATE INDEX idx_shipments_status
    ON shipments (status);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE shipments;
