import xml.etree.ElementTree as ET
import pandas as pd
import os
import time

xml_file = "/home/ubuntu/git/fennica/inst/examples/fennica_xml/Fennica_bibliot_20260413.xml"
out_file = "authors_700_long.csv"

NS = {"marc": "http://www.loc.gov/MARC21/slim"}

chunk = []
chunk_size = 50000

record_count = 0
author_row_count = 0
chunk_count = 0
start_time = time.time()

# remove old output if it exists
if os.path.exists(out_file):
    os.remove(out_file)

for event, elem in ET.iterparse(xml_file, events=("end",)):
    if elem.tag.endswith("record"):

        record_count += 1

        # 001
        field_001 = None
        for cf in elem.findall("marc:controlfield", NS):
            if cf.attrib.get("tag") == "001":
                field_001 = cf.text.strip() if cf.text else None
                break

        # 035$a
        ids_035a = []
        for df035 in elem.findall("marc:datafield[@tag='035']", NS):
            for sf in df035.findall("marc:subfield[@code='a']", NS):
                if sf.text:
                    ids_035a.append(sf.text.strip())

        field_035a = " | ".join(ids_035a) if ids_035a else None

        # 700 fields
        for df700 in elem.findall("marc:datafield[@tag='700']", NS):

            names = []
            ids = []

            for sf in df700.findall("marc:subfield", NS):
                code = sf.attrib.get("code")
                value = sf.text.strip() if sf.text else None

                if code == "a" and value:
                    names.append(value)

                elif code == "0" and value:
                    ids.append(value)

            chunk.append({
                "field_001": field_001,
                "field_035a": field_035a,
                "author_name": " | ".join(names) if names else None,
                "author_id": " | ".join(ids) if ids else None
            })

            author_row_count += 1

        # write chunk
        if len(chunk) >= chunk_size:
            chunk_count += 1

            pd.DataFrame(chunk).to_csv(
                out_file,
                mode="a",
                header=not os.path.exists(out_file),
                index=False,
                encoding="utf-8"
            )

            elapsed = time.time() - start_time
            print(
                f"Chunk {chunk_count} written | "
                f"records processed: {record_count:,} | "
                f"700 rows written: {author_row_count:,} | "
                f"elapsed: {elapsed/60:.1f} min"
            )

            chunk = []

        elem.clear()

# write remaining rows
if chunk:
    chunk_count += 1

    pd.DataFrame(chunk).to_csv(
        out_file,
        mode="a",
        header=not os.path.exists(out_file),
        index=False,
        encoding="utf-8"
    )

    print(f"Final chunk {chunk_count} written.")

elapsed = time.time() - start_time

print("Done.")
print(f"Total records processed: {record_count:,}")
print(f"Total 700 rows written: {author_row_count:,}")
print(f"Output file: {out_file}")
print(f"Total time: {elapsed/60:.1f} min")