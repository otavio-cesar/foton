using Foton.Domain.Quotes;

namespace Foton.Application.Quotes;

public interface IVirtualAssistantNotifier
{
    Task NotifyNewQuoteAsync(Quote quote, CancellationToken cancellationToken);
}
