using Spectre.Console.Cli;
using System;

namespace ItTiger.TigerWrap.Cli.Helpers;

public sealed class TypeResolver(IServiceProvider _provider) : ITypeResolver, IDisposable
{
    public object? Resolve(Type? type)
    {
        return type == null ? null : _provider.GetService(type);
    }

    public void Dispose()
    {
        if (_provider is IDisposable disposable)
        {
            disposable.Dispose();
        }
    }
}
