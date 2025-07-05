using System;
using ItTiger.TigerWrap.Core;

namespace ItTiger.TigerWrap.Cli.Helpers
{
    public sealed class CliException(ToolkitDbHelper.ToolkitResponseCode responseCode, string message) 
        : Exception(message)
    {
        public ToolkitDbHelper.ToolkitResponseCode ResponseCode { get; } = responseCode;

        
    }
}
