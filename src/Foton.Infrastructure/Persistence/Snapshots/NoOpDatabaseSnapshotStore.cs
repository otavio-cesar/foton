namespace Foton.Infrastructure.Persistence.Snapshots;

public sealed class NoOpDatabaseSnapshotStore : IDatabaseSnapshotStore
{
    public Task DownloadAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    public Task UploadAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
