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
            ParseElectricalSupplyType(request.ElectricalSupplyType),
            ParsePropertyType(request.PropertyType),
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

    private static ElectricalSupplyType ParseElectricalSupplyType(string value)
    {
        return value.Trim().ToLowerInvariant() switch
        {
            "monophasic-110" => ElectricalSupplyType.Monophasic110,
            "biphasic-220" => ElectricalSupplyType.Biphasic220,
            "triphasic" => ElectricalSupplyType.Triphasic,
            "single-phase-380" => ElectricalSupplyType.SinglePhase380,
            _ => throw new ArgumentException("Invalid electrical supply type.", nameof(value))
        };
    }

    private static PropertyType ParsePropertyType(string value)
    {
        return value.Trim().ToLowerInvariant() switch
        {
            "residence" => PropertyType.Residence,
            "condominium" => PropertyType.Condominium,
            "commercial" => PropertyType.Commercial,
            _ => throw new ArgumentException("Invalid property type.", nameof(value))
        };
    }
}
