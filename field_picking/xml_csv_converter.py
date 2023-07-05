from rdfpandas.graph import to_dataframe
import pandas as pd
import rdflib

def rdf_to_csv(input_file, output_file):
    g = rdflib.Graph()
    g.parse(input_file, format='xml')
    df = to_dataframe(g)
    df.to_csv(output_file, index = True, index_label = "@id")
    print(f"Conversion complete. CSV file saved as: {output_file}")
rdf_to_csv("finaf-skos.rdf","finaf-skos.csv")
