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
    return csvToArray(cast(string) read(filename));
}

private char[] filterQuotes(dchar quote)(const(char)[] str) pure
{
    auto buf = new char[str.length];
    size_t j = 0;
    for (size_t i = 0; i < str.length; i++)
    {
        if (str[i] == quote)
        {
            buf[j++] = '"';
            i++;

            if (i >= str.length)
                break;

            if (str[i] == quote)
                continue;
        }
        buf[j++] = str[i];
    }
    return buf[0 .. j];
}

/**
 * Parse CSV data into an input range of records.
 *
 * Params:
 *  fieldDelim = The field delimiter (default: ',')
 *  quote = The quote character (default: '"')
 *  input = The data in CSV format.
 *
 * Returns:
 *  An input range of records, each of which is an array of fields.
 */
auto csvByRecord(dchar fieldDelim=',', dchar quote='"')(const(char)[] input)
{
    struct Result
    {
        private enum fieldBlockSize = 1 << 16;
        private const(char)[] data;
        private const(char)[][] fields;
        private size_t i, curField;

        bool empty = true;
        const(char)[][] front;

        this(const(char)[] input)
        {
            data = input;
            fields = new const(char)[][fieldBlockSize];
            i = 0;
            curField = 0;
            empty = (input.length == 0);
            parseNextRecord();
        }

        void parseNextRecord()
        {
            size_t firstField = curField;
            while (i < data.length && data[i] != '\n' && data[i] != '\r')
            {
                // Parse fields
                size_t firstChar, lastChar;
                bool hasDoubledQuotes = false;

                if (data[i] == quote)
                {
                    import std.algorithm : max;

                    i++;
                    firstChar = i;
                    while (i < data.length)
                    {
                        if (data[i] == quote)
                        {
                            i++;
                            if (i >= data.length || data[i] != quote)
                                break;

                            hasDoubledQuotes = true;
                        }
                        i++;
                    }
                    assert(i-1 < data.length);
                    lastChar = max(firstChar, i-1);
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
                if (hasDoubledQuotes)
                    fields[curField++] = filterQuotes!quote(
                                            data[firstChar .. lastChar]);
                else
                    fields[curField++] = data[firstChar .. lastChar];

                // Skip over field delimiter
                if (i < data.length && data[i] == fieldDelim)
                    i++;
            }

            front = fields[firstField .. curField];

            // Skip over record delimiter(s)
            while (i < data.length && (data[i] == '\n' || data[i] == '\r'))
                i++;
        }

        void popFront()
        {
            if (i >= data.length)
            {
                empty = true;
                front = [];
            }
            else
                parseNextRecord();
        }
    }
    return Result(input);
}

/**
 * Parses CSV string data into an array of records.
 *
 * Params:
 *  fieldDelim = The field delimiter (default: ',')
 *  quote = The quote character (default: '"')
 *  input = The data in CSV format.
 *
 * Returns:
 *  An array of records, each of which is an array of fields.
 */
auto csvToArray(dchar fieldDelim=',', dchar quote='"')(const(char)[] input)
{
    import core.memory : GC;
    import std.array : array;

    GC.disable();
    auto result = input.csvByRecord!(fieldDelim, quote).array;
    GC.collect();
    GC.enable();
    return result;
}

unittest
{
    auto sampleData =
        `123,abc,"mno pqr",0` ~ "\n" ~
        `456,def,"stuv wx",1` ~ "\n" ~
        `78,ghijk,"yx",2`;

    auto parsed = csvToArray(sampleData);
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

    auto parsed = csvToArray(dosData);
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

    auto parsed = csvToArray(nastyData);
    assert(parsed == [
        [ "123", "abc", "ha ha \nha this is a split value", "567" ],
        [ "321", "a,comma,b", "def", "111" ]
    ]);
}

unittest
{
    // Quoted fields that contain quotes
    // (Note: RFC-4180 does not allow doubled quotes in unquoted fields)
    auto nastyData =
        `123,"a b ""haha"" c",456` ~ "\n";

    auto parsed = csvToArray(nastyData);
    assert(parsed == [
        [ "123", `a b "haha" c`, "456" ]
    ]);
}

// Boundary condition checks
unittest
{
    auto badData = `123,345,"def""`;
    auto parsed = csvToArray(badData);   // should not crash

    auto moreBadData = `123,345,"a"`;
    parsed = csvToArray(moreBadData);    // should not crash

    auto yetMoreBadData = `123,345,"`;
    parsed = csvToArray(yetMoreBadData); // should not crash

    auto emptyField = `123,,456`;
    parsed = csvToArray(emptyField);
    assert(parsed == [ [ "123", "", "456" ] ]);
}

version(none)
unittest
{
    auto data = csvFromUtf8File("ext/cbp13co.txt");
    import std.stdio;
    writefln("%d records", data.length);
}

// vim:set ai sw=4 ts=4 et:
