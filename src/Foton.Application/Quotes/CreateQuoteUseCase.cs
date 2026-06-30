using Foton.Domain.Quotes;

namespace Foton.Application.Quotes;

public sealed class CreateQuoteUseCase
{
    private readonly IQuoteRepository repository;
    private readonly IVirtualAssistantNotifier assistantNotifier;

    public CreateQuoteUseCase(IQuoteRepository repository, IVirtualAssistantNotifier assistantNotifier)
    {
        this.repository = repository;
        this.assistantNotifier = assistantNotifier;
    }

    public async Task<CreateQuoteResponse> ExecuteAsync(CreateQuoteRequest request, CancellationToken cancellationToken)
    {
        var quote = new Quote(
            request.Name,
            request.Phone,
            request.Email,
            request.City,
            ParseInstallationType(request.InstallationType),
            request.NeedsElectricalStandard,
            request.HasBiphasicNetwork,
            request.Message);

        await repository.AddAsync(quote, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);

        try
        {
            await assistantNotifier.NotifyNewQuoteAsync(quote, cancellationToken);
            quote.MarkAssistantNotified();
        }
        catch
        {
            quote.MarkAssistantFailed();
        }

        await repository.SaveChangesAsync(cancellationToken);
        return new CreateQuoteResponse(quote.Id, quote.Status.ToString());
    }

    private static InstallationType ParseInstallationType(string value)
    {
        return value.Trim().ToLowerInvariant() switch
        {
            "charger" => InstallationType.Charger,
            "totem" => InstallationType.Totem,
            "both" => InstallationType.Both,
            "not-sure" => InstallationType.NotSure,
            _ => throw new ArgumentException("Invalid installation type.", nameof(value))
        };
    }
}
