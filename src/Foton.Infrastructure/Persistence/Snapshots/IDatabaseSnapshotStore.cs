namespace Foton.Infrastructure.Persistence.Snapshots;

public interface IDatabaseSnapshotStore
{
    Task DownloadAsync(CancellationToken cancellationToken);

    Task UploadAsync(CancellationToken cancellationToken);
}
