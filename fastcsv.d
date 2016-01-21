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
auto csvFromString(dchar fieldDelim = ',')(const(char)[] data)
{
    import std.array : appender;

    enum fieldBlockSize = 1 << 16;
    auto fields = new const(char)[][fieldBlockSize];
    size_t curField = 0;

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
            size_t firstChar = i;
            while (i < data.length && data[i] != fieldDelim &&
                   data[i] != '\n' && data[i] != '\r')
            {
                i++;
            }
            if (curField >= fields.length)
            {
                // Fields block is full; copy current record fields into new
                // block so that they are contiguous.
                auto nextFields = new const(char)[][fieldBlockSize];
                nextFields[0 .. curField - firstField] =
                    fields[firstField .. curField];

                //fields.length = firstField; // release unused memory?

                firstField = 0;
                curField = firstField - curField;
                fields = nextFields;
            }
            assert(curField < fields.length);
            fields[curField++] = data[firstChar .. i];

            // Skip over field delimiter
            if (i < data.length && data[i] == fieldDelim)
                i++;
        }
        app.put(fields[firstField .. curField]);

        // Skip over record delimiter(s)
        while (i < data.length && (data[i] == '\n' || data[i] == '\r'))
            i++;
    }

    return app.data;
}

unittest
{
    auto sampleData =
        `123,abc,"mno pqr",0`~"\n"~
        `456,def,"stuv wx",1`~"\n"~
        `78,ghijk,"yx",2`;

    auto parsed = csvFromString(sampleData);
    assert(parsed == [
        [ "123", "abc", `"mno pqr"`, "0" ],
        [ "456", "def", `"stuv wx"`, "1" ],
        [ "78", "ghijk", `"yx"`, "2" ]
    ]);
}

// vim:set ai sw=4 ts=4 et:
