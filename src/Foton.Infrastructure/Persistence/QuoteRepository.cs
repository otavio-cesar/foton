using Foton.Application.Quotes;
using Foton.Domain.Quotes;
using Foton.Infrastructure.Persistence.Snapshots;

namespace Foton.Infrastructure.Persistence;

public sealed class QuoteRepository : IQuoteRepository
{
    private readonly FotonDbContext dbContext;
    private readonly IDatabaseSnapshotStore snapshotStore;

    public QuoteRepository(FotonDbContext dbContext, IDatabaseSnapshotStore snapshotStore)
    {
        this.dbContext = dbContext;
        this.snapshotStore = snapshotStore;
    }

    public async Task AddAsync(Quote quote, CancellationToken cancellationToken)
    {
        await dbContext.Quotes.AddAsync(quote, cancellationToken);
    }

    public async Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        await dbContext.SaveChangesAsync(cancellationToken);
        await snapshotStore.UploadAsync(cancellationToken);
    }
}
