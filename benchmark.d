/**
 * Crude benchmark for fastcsv.
 */
import core.memory;
import std.array;
import std.csv;
import std.file;
import std.datetime : benchmark;
import std.stdio;

import fastcsv;

struct Layout
{
    string fipstate;
    string fipscty;
    string naics;
    string empflag;
    string emp_nf;
    int emp;
    string qp1_nf;
    int qp1;
    string ap_nf;
    int ap;
    int est;
    int n1_4;
    int n5_9;
    int n10_19;
    int n20_49;
    int n50_99;
    int n100_249;
    int n250_499;
    int n500_999;
    int n1000;
    int n1000_1;
    int n1000_2;
    int n1000_3;
    int n1000_4;
    string censtate;
    string cencty;
}

struct Layout2
{
    const(char)[] fipstate;
    const(char)[] fipscty;
    const(char)[] naics;
    const(char)[] empflag;
    const(char)[] emp_nf;
    int emp;
    const(char)[] qp1_nf;
    int qp1;
    const(char)[] ap_nf;
    int ap;
    int est;
    int n1_4;
    int n5_9;
    int n10_19;
    int n20_49;
    int n50_99;
    int n100_249;
    int n250_499;
    int n500_999;
    int n1000;
    int n1000_1;
    int n1000_2;
    int n1000_3;
    int n1000_4;
    const(char)[] censtate;
    const(char)[] cencty;
}

int main(string[] argv)
{
    // Obtained from ftp://ftp.census.gov/econ2013/CBP_CSV/cbp13co.zip
    string csvFile = "ext/cbp13co.txt";

    if (argv.length < 2)
    {
        stderr.writeln("Specify std, stdnogc, fastwithgc, fast, stdstruct, "~
                       "faststruct, faststruct2");
        return 1;
    }

    if (argv.length >= 3)
        csvFile = argv[2];

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
    else if (argv[1] == "fastwithgc")
    {
        auto result = benchmark!({
            import std.array : array;
            auto data = input.csvByRecord.array;
            writefln("fastcsv read %d records", data.length);
        })(1);
        writefln("fastcsv (with gc): %s msecs", result[0].msecs);
    }
    else if (argv[1] == "fast")
    {
        auto result = benchmark!({
            auto data = fastcsv.csvToArray(input);
            writefln("fastcsv read %d records", data.length);
        })(1);
        writefln("fastcsv (no gc): %s msecs", result[0].msecs);
    }
    else if (argv[1] == "stdstruct")
    {
        auto result = benchmark!({
            string[] header;
            auto data = std.csv.csvReader!Layout(input, header).array;
            writefln("std.csv read %d records", data.length);
        })(1);
        writefln("std.csv (struct): %s msecs", result[0].msecs);
    }
    else if (argv[1] == "faststruct")
    {
        auto result = benchmark!({
            auto data = fastcsv.csvByStruct!Layout(input).array;
            writefln("fastcsv read %d records", data.length);
        })(1);
        writefln("fastcsv (struct): %s msecs", result[0].msecs);
    }
    else if (argv[1] == "faststruct2")
    {
        auto result = benchmark!({
            auto data = fastcsv.csvByStruct!Layout2(input).array;
            writefln("fastcsv read %d records", data.length);
        })(1);
        writefln("fastcsv (struct with const(char)[]): %s msecs",
                 result[0].msecs);
    }
    else
    {
        stderr.writeln("Unknown option: " ~ argv[1]);
        return 1;
    }
    return 0;
}

// vim:set ai sw=4 ts=4 et:
