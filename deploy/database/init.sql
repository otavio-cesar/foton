CREATE TABLE IF NOT EXISTS quotes (
    "Id" uuid PRIMARY KEY,
    "Name" varchar(160) NOT NULL,
    "Phone" varchar(40) NOT NULL,
    "Email" varchar(180) NOT NULL,
    "City" varchar(120) NOT NULL,
    "InstallationType" varchar(32) NOT NULL,
    "NeedsElectricalStandard" boolean NOT NULL,
    "HasBiphasicNetwork" boolean NOT NULL,
    "Message" varchar(2000) NOT NULL,
    "Status" varchar(32) NOT NULL,
    "CreatedAtUtc" timestamptz NOT NULL,
    "AssistantNotifiedAtUtc" timestamptz NULL
);

CREATE INDEX IF NOT EXISTS ix_quotes_created_at_utc ON quotes ("CreatedAtUtc");
