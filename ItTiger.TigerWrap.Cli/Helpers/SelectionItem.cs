namespace ItTiger.TigerWrap.Cli.Helpers
{
    public sealed class SelectionItem<T>(T value, string label)
    {
        public T Value { get; } = value;
        public string Label { get; } = label;

        public override string ToString() => Label;
    }
}
