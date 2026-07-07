using Foton.Application.Quotes;
using Foton.Infrastructure.Assistants;
using Foton.Infrastructure.Persistence;
using Foton.Infrastructure.Persistence.Snapshots;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Foton.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<DatabaseSnapshotOptions>(options =>
        {
            options.BucketName = configuration["Database:Snapshot:BucketName"];
            options.ObjectKey = configuration["Database:Snapshot:ObjectKey"] ?? options.ObjectKey;
            options.LocalPath = configuration["Database:Snapshot:LocalPath"] ?? options.LocalPath;
            options.Region = configuration["Database:Snapshot:Region"];
        });

        services.AddDbContext<FotonDbContext>(options =>
        {
            var localPath = configuration["Database:Snapshot:LocalPath"] ?? "/app/data/foton.db";
            var directory = Path.GetDirectoryName(localPath);

            if (!string.IsNullOrWhiteSpace(directory))
            {
                Directory.CreateDirectory(directory);
            }

            options.UseSqlite($"Data Source={localPath}");
        });

        if (string.IsNullOrWhiteSpace(configuration["Database:Snapshot:BucketName"]))
        {
            services.AddSingleton<IDatabaseSnapshotStore, NoOpDatabaseSnapshotStore>();
        }
        else
        {
            services.AddSingleton<IDatabaseSnapshotStore, S3DatabaseSnapshotStore>();
        }

        services.AddScoped<IQuoteRepository, QuoteRepository>();
        services.AddScoped<IVirtualAssistantNotifier, LoggingVirtualAssistantNotifier>();

        return services;
    }
}
