using Foton.Application.Quotes;
using Foton.Infrastructure;
using Foton.Infrastructure.Persistence;
using Foton.Infrastructure.Persistence.Snapshots;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("web", policy =>
    {
        var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
            ?? ["http://localhost:4200"];

        if (allowedOrigins.Contains("*"))
        {
            policy.AllowAnyOrigin();
        }
        else
        {
            policy.WithOrigins(allowedOrigins);
        }

        policy
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

builder.Services.AddScoped<CreateQuoteUseCase>();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddHealthChecks();

var app = builder.Build();

if (app.Configuration.GetValue("Database:EnsureCreatedOnStartup", false))
{
    var snapshotStore = app.Services.GetRequiredService<IDatabaseSnapshotStore>();
    await snapshotStore.DownloadAsync(CancellationToken.None);

    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<FotonDbContext>();
    await dbContext.Database.EnsureCreatedAsync();
    await EnsureQuoteColumnsAsync(dbContext, CancellationToken.None);

    await snapshotStore.UploadAsync(CancellationToken.None);
}

app.UseCors("web");

app.MapHealthChecks("/health");

app.MapPost("/api/quotes", async (
    CreateQuoteRequest request,
    CreateQuoteUseCase useCase,
    CancellationToken cancellationToken) =>
{
    try
    {
        var response = await useCase.ExecuteAsync(request, cancellationToken);
        return Results.Created($"/api/quotes/{response.Id}", response);
    }
    catch (ArgumentException exception)
    {
        return Results.BadRequest(new { error = exception.Message });
    }
});

app.Run();

static async Task EnsureQuoteColumnsAsync(FotonDbContext dbContext, CancellationToken cancellationToken)
{
    var connection = dbContext.Database.GetDbConnection();
    await connection.OpenAsync(cancellationToken);

    try
    {
        var columns = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        await using (var command = connection.CreateCommand())
        {
            command.CommandText = "PRAGMA table_info(quotes);";
            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            while (await reader.ReadAsync(cancellationToken))
            {
                columns.Add(reader.GetString(1));
            }
        }

        if (!columns.Contains("ElectricalSupplyType"))
        {
            await dbContext.Database.ExecuteSqlRawAsync(
                "ALTER TABLE quotes ADD COLUMN ElectricalSupplyType TEXT NOT NULL DEFAULT 'Unknown';",
                cancellationToken);
        }

        if (!columns.Contains("PropertyType"))
        {
            await dbContext.Database.ExecuteSqlRawAsync(
                "ALTER TABLE quotes ADD COLUMN PropertyType TEXT NOT NULL DEFAULT 'Unknown';",
                cancellationToken);
        }
    }
    finally
    {
        await connection.CloseAsync();
    }
}
