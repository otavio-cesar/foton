using Foton.Application.Quotes;
using Foton.Infrastructure.Assistants;
using Foton.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Foton.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<FotonDbContext>(options =>
        {
            var connectionString = configuration.GetConnectionString("FotonDb")
                ?? throw new InvalidOperationException("Connection string FotonDb is required.");

            options.UseNpgsql(connectionString);
        });

        services.AddScoped<IQuoteRepository, QuoteRepository>();
        services.AddScoped<IVirtualAssistantNotifier, LoggingVirtualAssistantNotifier>();

        return services;
    }
}
