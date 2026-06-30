using Foton.Domain.Quotes;
using Microsoft.EntityFrameworkCore;

namespace Foton.Infrastructure.Persistence;

public sealed class FotonDbContext : DbContext
{
    public FotonDbContext(DbContextOptions<FotonDbContext> options)
        : base(options)
    {
    }

    public DbSet<Quote> Quotes => Set<Quote>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Quote>(entity =>
        {
            entity.ToTable("quotes");
            entity.HasKey(quote => quote.Id);
            entity.Property(quote => quote.Name).HasMaxLength(160).IsRequired();
            entity.Property(quote => quote.Phone).HasMaxLength(40).IsRequired();
            entity.Property(quote => quote.Email).HasMaxLength(180).IsRequired();
            entity.Property(quote => quote.City).HasMaxLength(120).IsRequired();
            entity.Property(quote => quote.InstallationType).HasConversion<string>().HasMaxLength(32);
            entity.Property(quote => quote.Status).HasConversion<string>().HasMaxLength(32);
            entity.Property(quote => quote.Message).HasMaxLength(2000);
            entity.Property(quote => quote.CreatedAtUtc).IsRequired();
        });
    }
}
