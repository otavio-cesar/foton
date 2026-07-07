using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Foton.Infrastructure.Persistence.Snapshots;

public sealed class S3DatabaseSnapshotStore : IDatabaseSnapshotStore
{
    private readonly IAmazonS3 s3Client;
    private readonly DatabaseSnapshotOptions options;
    private readonly ILogger<S3DatabaseSnapshotStore> logger;

    public S3DatabaseSnapshotStore(
        IOptions<DatabaseSnapshotOptions> options,
        ILogger<S3DatabaseSnapshotStore> logger)
    {
        this.options = options.Value;
        this.logger = logger;

        var regionName = this.options.Region
            ?? Environment.GetEnvironmentVariable("AWS_REGION")
            ?? Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION")
            ?? "sa-east-1";

        s3Client = new AmazonS3Client(RegionEndpoint.GetBySystemName(regionName));
    }

    public async Task DownloadAsync(CancellationToken cancellationToken)
    {
        EnsureLocalDirectory();

        if (!options.Enabled)
        {
            return;
        }

        try
        {
            var request = new GetObjectRequest
            {
                BucketName = options.BucketName,
                Key = options.ObjectKey
            };

            using var response = await s3Client.GetObjectAsync(request, cancellationToken);
            await response.WriteResponseStreamToFileAsync(options.LocalPath, false, cancellationToken);
            logger.LogInformation("SQLite snapshot downloaded from s3://{Bucket}/{Key}.", options.BucketName, options.ObjectKey);
        }
        catch (AmazonS3Exception exception) when (exception.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            logger.LogInformation("SQLite snapshot not found in S3. A new local database will be created.");
        }
    }

    public async Task UploadAsync(CancellationToken cancellationToken)
    {
        if (!options.Enabled || !File.Exists(options.LocalPath))
        {
            return;
        }

        var request = new PutObjectRequest
        {
            BucketName = options.BucketName,
            Key = options.ObjectKey,
            FilePath = options.LocalPath,
            ContentType = "application/x-sqlite3",
            ServerSideEncryptionMethod = ServerSideEncryptionMethod.AES256
        };

        await s3Client.PutObjectAsync(request, cancellationToken);
        logger.LogInformation("SQLite snapshot uploaded to s3://{Bucket}/{Key}.", options.BucketName, options.ObjectKey);
    }

    private void EnsureLocalDirectory()
    {
        var directory = Path.GetDirectoryName(options.LocalPath);

        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }
}
