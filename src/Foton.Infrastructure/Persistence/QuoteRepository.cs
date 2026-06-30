using Foton.Application.Quotes;
using Foton.Domain.Quotes;

namespace Foton.Infrastructure.Persistence;

public sealed class QuoteRepository : IQuoteRepository
{
    private readonly FotonDbContext dbContext;

    public QuoteRepository(FotonDbContext dbContext)
    {
        this.dbContext = dbContext;
    }

    public async Task AddAsync(Quote quote, CancellationToken cancellationToken)
    {
        await dbContext.Quotes.AddAsync(quote, cancellationToken);
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        return dbContext.SaveChangesAsync(cancellationToken);
    }
}
