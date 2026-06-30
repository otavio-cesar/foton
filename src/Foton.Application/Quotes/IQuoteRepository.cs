using Foton.Domain.Quotes;

namespace Foton.Application.Quotes;

public interface IQuoteRepository
{
    Task AddAsync(Quote quote, CancellationToken cancellationToken);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
