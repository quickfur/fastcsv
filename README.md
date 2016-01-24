Fast CSV parser in D
====================

This is an experimental project in improving the performance of loading CSV
files in D.

Its features include:

- Extremely fast. It can run up to about 18x faster than std.csv (as of Jan
  2016, using a 2.1 million record CSV test file).

- Parses anything that conforms to RFC 4810.

- Optional range-based interface (returns an input range of records).

- Supports fast transcription of CSV data to a range of structs. Specially
  optimized for structs with string fields, that outperforms std.csv by an
  order of magnitude.

Its limitations are:

- Does not perform data validation. Will produce nonsensical results for
  malformed CSV data (anything not conformant to RFC 4810).

- Requires the input data to be entirely in memory. This may not be practical
  for very large CSV files or low-memory machines.

- Cannot handle CSV data containing records that have more than 4096 fields
  each.

- Cannot handle string fields larger than 64KB.

- The input range interface still requires the entire input data to be an
  in-memory string. No forward range capability is provided.

- Requires UTF-8 input. Does not support UTF-16 or UTF-32 or other encodings.

Usage:

	import std.file;
	import fastcsv;

	// Load CSV into memory
	auto input = cast(string) read(myCsvFile);

	// Convert CSV to array
	const(char)[][] mydata = csvToArray(input);

	// Iterate over CSV as input range
	foreach (record; csvByRecord(input))
	{
	    // do something with record (as array of string values)
	}

