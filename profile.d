import std.file;
import fastcsv;

void main()
{
    enum csvFile = "ext/cbp13co.txt";
    auto input = cast(string) read(csvFile);
    auto data = fastcsv.csvFromString(input);
}

// vim:set ai sw=4 ts=4 et:
