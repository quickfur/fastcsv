/**
 * Crude benchmark for fastcsv.
 */
import std.array;
import std.csv;
import std.file;
import std.datetime;
import std.stdio;

import fastcsv;

void main()
{
    // Obtained from ftp://ftp.census.gov/econ2013/CBP_CSV/cbp13co.zip
    enum csvFile = "ext/cbp13co.txt";

    auto input = cast(string) read(csvFile);
    auto result = benchmark!(
        {
            auto data = std.csv.csvReader(input).array;
            writefln("std.csv read %d records", data.length);
        },
        {
            auto data = fastcsv.csvFromString(input);
            writefln("fastcsv read %d records", data.length);
        },
    )(1);

    import std.conv : to;
    writefln("std.csv: %s msecs", result[0].msecs);
    writefln("fastcsv: %s msecs", result[1].msecs);
}

// vim:set ai sw=4 ts=4 et:
