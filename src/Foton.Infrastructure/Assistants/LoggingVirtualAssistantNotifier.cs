using Foton.Application.Quotes;
using Foton.Domain.Quotes;
using Microsoft.Extensions.Logging;

namespace Foton.Infrastructure.Assistants;

public sealed class LoggingVirtualAssistantNotifier : IVirtualAssistantNotifier
{
    private readonly ILogger<LoggingVirtualAssistantNotifier> logger;

    public LoggingVirtualAssistantNotifier(ILogger<LoggingVirtualAssistantNotifier> logger)
    {
        this.logger = logger;
    }

    public Task NotifyNewQuoteAsync(Quote quote, CancellationToken cancellationToken)
    {
        logger.LogInformation(
            "Virtual assistant notification placeholder for quote {QuoteId} from {Name} in {City}.",
            quote.Id,
            quote.Name,
            quote.City);

        return Task.CompletedTask;
    }
}
