using System;
using System.Text.Json.Serialization;
using BaGetter.Authentication;
using BaGetter.Core;
using BaGetter.Web;
using BaGetter.Web.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.DependencyInjection;

namespace BaGetter;

public static class IServiceCollectionExtensions
{
    public static IServiceCollection AddBaGetterWebApplication(
        this IServiceCollection services,
        Action<BaGetterApplication> configureAction)
    {
        services
            .AddRouting(options => options.LowercaseUrls = true)
            .AddControllers()
            .AddApplicationPart(typeof(PackageContentController).Assembly)
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
            });

        services.AddHttpContextAccessor();
        services.AddTransient<IUrlGenerator, BaGetterUrlGenerator>();

        var app = services.AddBaGetterApplication(configureAction);

        return services;
    }
}
