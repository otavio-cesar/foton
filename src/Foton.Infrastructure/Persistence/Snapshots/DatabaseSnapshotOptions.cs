namespace Foton.Infrastructure.Persistence.Snapshots;

public sealed class DatabaseSnapshotOptions
{
    public string? BucketName { get; set; }

    public string ObjectKey { get; set; } = "sqlite/foton.db";

    public string LocalPath { get; set; } = "/app/data/foton.db";

    public string? Region { get; set; }

    public bool Enabled => !string.IsNullOrWhiteSpace(BucketName);
}
