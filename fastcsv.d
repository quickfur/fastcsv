/**
 * Experimental fast CSV reader.
 *
 * Based on RFC 4180.
 */
module fastcsv;

/**
 * Reads CSV data from the given filename.
 */
auto csvFromUtf8File(string filename)
{
    import std.file : read;
    return csvFromString(cast(string) read(filename));
}

/**
 * Parses CSV data in a string.
 *
 * Params:
 *  fieldDelim = The field delimiter (default: ',')
 *  data = The data in CSV format.
 */
auto csvFromString(dchar fieldDelim=',', dchar quote='"')(const(char)[] data)
{
    import core.memory;
    import std.array : appender;

    enum fieldBlockSize = 1 << 16;
    auto fields = new const(char)[][fieldBlockSize];
    size_t curField = 0;

    GC.disable();
    auto app = appender!(const(char)[][][]);

    // Scan data
    size_t i;
    while (i < data.length)
    {
        // Parse records
        size_t firstField = curField;
        while (i < data.length && data[i] != '\n' && data[i] != '\r')
        {
            // Parse fields
            size_t firstChar, lastChar;
            if (data[i] == quote)
            {
                i++;
                firstChar = i;
                while (i < data.length)
                {
                    if (data[i] == quote)
                    {
                        i++;
                        if (data[i] != quote)
                            break;

                        i++;
                    }
                    else
                        i++;
                }
                lastChar = (i < data.length && data[i-1] == quote) ? i-1 : i;
            }
            else
            {
                firstChar = i;
                while (i < data.length && data[i] != fieldDelim &&
                       data[i] != '\n' && data[i] != '\r')
                {
                    i++;
                }
                lastChar = i;
            }
            if (curField >= fields.length)
            {
                // Fields block is full; copy current record fields into new
                // block so that they are contiguous.
                auto nextFields = new const(char)[][fieldBlockSize];
                nextFields[0 .. curField - firstField] =
                    fields[firstField .. curField];

                //fields.length = firstField; // release unused memory?

                curField = curField - firstField;
                firstField = 0;
                fields = nextFields;
            }
            assert(curField < fields.length);
            fields[curField++] = data[firstChar .. lastChar];

            // Skip over field delimiter
            if (i < data.length && data[i] == fieldDelim)
                i++;
        }
        app.put(fields[firstField .. curField]);

        // Skip over record delimiter(s)
        while (i < data.length && (data[i] == '\n' || data[i] == '\r'))
            i++;
    }

    GC.collect();
    GC.enable();
    return app.data;
}

unittest
{
    auto sampleData =
        `123,abc,"mno pqr",0` ~ "\n" ~
        `456,def,"stuv wx",1` ~ "\n" ~
        `78,ghijk,"yx",2`;

    auto parsed = csvFromString(sampleData);
    assert(parsed == [
        [ "123", "abc", "mno pqr", "0" ],
        [ "456", "def", "stuv wx", "1" ],
        [ "78", "ghijk", "yx", "2" ]
    ]);
}

unittest
{
    auto dosData =
        `123,aa,bb,cc` ~ "\r\n" ~
        `456,dd,ee,ff` ~ "\r\n" ~
        `789,gg,hh,ii` ~ "\r\n";

    auto parsed = csvFromString(dosData);
    assert(parsed == [
        [ "123", "aa", "bb", "cc" ],
        [ "456", "dd", "ee", "ff" ],
        [ "789", "gg", "hh", "ii" ]
    ]);
}

unittest
{
    // Quoted fields that contains newlines and delimiters
    auto nastyData =
        `123,abc,"ha ha ` ~ "\n" ~
        `ha this is a split value",567` ~ "\n" ~
        `321,"a,comma,b",def,111` ~ "\n";

    auto parsed = csvFromString(nastyData);
    assert(parsed == [
        [ "123", "abc", "ha ha \nha this is a split value", "567" ],
        [ "321", "a,comma,b", "def", "111" ]
    ]);
}

unittest
{
    // Unquoted fields that contain quotes
    auto nastyData =
        `123,a b ""haha"" c,456` ~ "\n";

    auto parsed = csvFromString(nastyData);
    assert(parsed == [
        [ "123", `a b ""haha"" c`, "456" ]
    ]);
}

version(none)
unittest
{
    auto data = csvFromUtf8File("ext/cbp13co.txt");
    import std.stdio;
    writefln("%d records", data.length);
}

// vim:set ai sw=4 ts=4 et:
