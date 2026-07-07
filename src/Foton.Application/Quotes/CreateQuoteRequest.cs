namespace Foton.Application.Quotes;

public sealed record CreateQuoteRequest(
    string Name,
    string Phone,
    string Email,
    string City,
    string ElectricalSupplyType,
    string PropertyType,
    string? Message);
