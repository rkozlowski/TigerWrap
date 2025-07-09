using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ItTiger.TigerWrap.Cli.Helpers;

public enum BoolChoice
{
    No = 0,
    Yes = 1
}

public static class BoolChoiceExtensions
{
    public static bool? ToNullableBool(this BoolChoice? choice)
    {
        return choice switch
        {
            BoolChoice.Yes => true,
            BoolChoice.No => false,
            null => null,
            _ => null
        };
    }

    public static BoolChoice? ToBoolChoice(this bool? value)
    {
        return value switch
        {
            true => BoolChoice.Yes,
            false => BoolChoice.No,
            null => null
        };
    }

    public static BoolChoice ToBoolChoice(this bool value)
    {
        return value ? BoolChoice.Yes : BoolChoice.No;
    }

    public static bool AsBool(this BoolChoice? choice, bool defaultValue = false)
    {
        return choice switch
        {
            BoolChoice.Yes => true,
            BoolChoice.No => false,
            null => defaultValue,
            _ => throw new NotImplementedException()
        };
    }
    public static bool AsBool(this BoolChoice choice)
    {
        return choice switch
        {
            BoolChoice.Yes => true,
            BoolChoice.No => false,            
            _ => throw new NotImplementedException()
        };
    }

}
