namespace Foton.Application.Quotes;

public sealed record CreateQuoteRequest(
    string Name,
    string Phone,
    string Email,
    string City,
    string InstallationType,
    bool NeedsElectricalStandard,
    bool HasBiphasicNetwork,
    string? Message);
