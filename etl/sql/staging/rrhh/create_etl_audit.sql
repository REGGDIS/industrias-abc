CREATE TABLE IF NOT EXISTS etl_execution_log (
    execution_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source VARCHAR(50) NOT NULL,
    process VARCHAR(100) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    finished_at TIMESTAMP,
    records_read INTEGER NOT NULL DEFAULT 0,
    records_valid INTEGER NOT NULL DEFAULT 0,
    records_rejected INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL,
    message TEXT
);