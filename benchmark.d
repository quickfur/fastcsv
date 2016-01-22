/**
 * Crude benchmark for fastcsv.
 */
import core.memory;
import std.array;
import std.csv;
import std.file;
import std.datetime;
import std.stdio;

import fastcsv;

int main(string[] argv)
{
    if (argv.length < 2)
    {
        stderr.writeln("Specify std, stdnogc, or fast");
        return 1;
    }

    // Obtained from ftp://ftp.census.gov/econ2013/CBP_CSV/cbp13co.zip
    enum csvFile = "ext/cbp13co.txt";

    string input = cast(string) read(csvFile);

    if (argv[1] == "std")
    {
        auto result = benchmark!({
            auto data = std.csv.csvReader(input).array;
            writefln("std.csv read %d records", data.length);
        })(1);
        writefln("std.csv: %s msecs", result[0].msecs);
    }
    else if (argv[1] == "stdnogc")
    {
        auto result = benchmark!({
            GC.disable();
            auto data = std.csv.csvReader(input).array;
            writefln("std.csv (nogc) read %d records", data.length);
            GC.enable();
        })(1);
        writefln("std.csv: %s msecs", result[0].msecs);
    }
    else if (argv[1] == "fast")
    {
        auto result = benchmark!({
            auto data = fastcsv.csvToArray(input);
            writefln("fastcsv read %d records", data.length);
        })(1);
        writefln("fastcsv: %s msecs", result[0].msecs);
    }
    else
    {
        stderr.writeln("Unknown option: " ~ argv[1]);
        return 1;
    }
    return 0;
}

// vim:set ai sw=4 ts=4 et:
