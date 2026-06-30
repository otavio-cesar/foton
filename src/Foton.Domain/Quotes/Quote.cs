namespace Foton.Domain.Quotes;

public sealed class Quote
{
    private Quote()
    {
    }

    public Quote(
        string name,
        string phone,
        string email,
        string city,
        InstallationType installationType,
        bool needsElectricalStandard,
        bool hasBiphasicNetwork,
        string? message)
    {
        Id = Guid.NewGuid();
        Name = Required(name, nameof(name));
        Phone = Required(phone, nameof(phone));
        Email = Required(email, nameof(email));
        City = Required(city, nameof(city));
        InstallationType = installationType;
        NeedsElectricalStandard = needsElectricalStandard;
        HasBiphasicNetwork = hasBiphasicNetwork;
        Message = message?.Trim() ?? string.Empty;
        Status = QuoteStatus.Received;
        CreatedAtUtc = DateTimeOffset.UtcNow;
    }

    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Phone { get; private set; } = string.Empty;
    public string Email { get; private set; } = string.Empty;
    public string City { get; private set; } = string.Empty;
    public InstallationType InstallationType { get; private set; }
    public bool NeedsElectricalStandard { get; private set; }
    public bool HasBiphasicNetwork { get; private set; }
    public string Message { get; private set; } = string.Empty;
    public QuoteStatus Status { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset? AssistantNotifiedAtUtc { get; private set; }

    public void MarkAssistantNotified()
    {
        Status = QuoteStatus.AssistantNotified;
        AssistantNotifiedAtUtc = DateTimeOffset.UtcNow;
    }

    public void MarkAssistantFailed()
    {
        Status = QuoteStatus.AssistantFailed;
    }

    private static string Required(string value, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"{fieldName} is required.", fieldName);
        }

        return value.Trim();
    }
}
