using Spectre.Console.Cli;
using Spectre.Console;
using Microsoft.Extensions.DependencyInjection;
using ItTiger.TigerWrap.Core;
using ItTiger.TigerWrap.Cli.Commands;
using NLog;
using NLog.Extensions.Logging;
using ItTiger.TigerWrap.Cli.Commands.Connections;
using ItTiger.TigerWrap.Cli.Helpers;
using ItTiger.TigerWrap.Core.Services;
using ItTiger.TigerWrap.Cli.Commands.Projects;
using Microsoft.Extensions.Logging;

namespace ItTiger.TigerWrap.Cli;

class Program
{
    public static int Main(string[] args)
    {
        // Setup DI & Spectre
        var services = new ServiceCollection();
        
        services.AddLogging(logging =>
        {
            logging.ClearProviders();
            logging.SetMinimumLevel(Microsoft.Extensions.Logging.LogLevel.Debug);
            logging.AddNLog(); // if using NLog
        });

        services.AddSingleton<ConnectionService>();

        var registrar = new TypeRegistrar(services);

        var app = new CommandApp(registrar);

        app.Configure(config =>
        {
            config.SetApplicationName("mssql-helper");

            config.AddBranch("connections", connections =>
            {
                connections.AddCommand<ConnectionsListCommand>("list");
                connections.AddCommand<ConnectionsAddCommand>("add");
                connections.AddCommand<ConnectionsDeleteCommand>("delete");
                connections.AddCommand<ConnectionsUpdateCommand>("update");
            });
            config.AddBranch("projects", projects =>
            {
                projects.AddCommand<ProjectsListCommand>("list");
                projects.AddCommand<ProjectsShowCommand>("show");
                projects.AddCommand<ProjectsAddCommand>("add");
                projects.AddBranch("sp", sp =>
                {
                    sp.AddCommand<ProjectsSpAddCommand>("add");
                    sp.AddCommand<ProjectsSpRemoveCommand>("remove");                    
                });
                projects.AddBranch("enum", en =>
                {
                    en.AddCommand<ProjectsEnumAddCommand>("add");
                    en.AddCommand<ProjectsEnumRemoveCommand>("remove");                    
                });
                projects.AddBranch("norm", nm =>
                {
                    nm.AddCommand<ProjectsNormAddCommand>("add");
                    nm.AddCommand<ProjectsNormRemoveCommand>("remove");                    
                });                
            });
            config.AddCommand<GenerateCodeCommand>("generate-code");
            config.AddCommand<LanguagesListCommand>("languages-list");
            config.AddCommand<VersionCommand>("version");
            config.ValidateExamples();
        });

        return app.Run(args);
    }
}
