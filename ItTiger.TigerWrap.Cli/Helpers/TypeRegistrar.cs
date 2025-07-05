using Microsoft.Extensions.DependencyInjection;
using Spectre.Console.Cli;
using System;

namespace ItTiger.TigerWrap.Cli.Helpers
{


    public sealed class TypeRegistrar(IServiceCollection _builder) : ITypeRegistrar
    {
        public ITypeResolver Build()
        {
            return new TypeResolver(_builder.BuildServiceProvider());
        }

        public void Register(Type service, Type implementation)
        {
            _builder.AddSingleton(service, implementation);
        }

        public void RegisterInstance(Type service, object implementation)
        {
            _builder.AddSingleton(service, implementation);
        }

        public void RegisterLazy(Type service, Func<object> factory)
        {
            _builder.AddSingleton(service, provider => factory());
        }
    }
}
