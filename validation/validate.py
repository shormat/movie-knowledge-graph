"""Validate the generated knowledge graph against the SHACL shapes.

Steps:
1. Load the OWL 2 QL ontology and materialise the owl:inverseOf axioms
   (each inverse property gets the swapped domain/range), so that pySHACL's
   RDFS inference can use them. The result is written to
   ontology/krr_QL_expanded.ttl.
2. Validate data/output.ttl against validation/shacl.ttl, using the expanded
   ontology as the ontology graph.

Run from anywhere: `python validation/validate.py` (or `make validate`).
"""
import sys
from pathlib import Path

from pyshacl import validate
from rdflib import Graph, OWL, RDFS

ROOT = Path(__file__).resolve().parent.parent
ONTOLOGY = ROOT / "ontology" / "krr_QL.ttl"
EXPANDED_ONTOLOGY = ROOT / "ontology" / "krr_QL_expanded.ttl"
DATA = ROOT / "data" / "output.ttl"
SHAPES = ROOT / "validation" / "shacl.ttl"

g = Graph()
g.parse(ONTOLOGY, format="turtle")
# like SPARQL "SELECT ?s ?o WHERE { ?s owl:inverseOf ?o }"
for s, p, o in list(g.triples((None, OWL.inverseOf, None))):
    g.add((o, OWL.inverseOf, s))
    for d in list(g.objects(s, RDFS.domain)):
        g.add((o, RDFS.range, d))
    for r in list(g.objects(s, RDFS.range)):
        g.add((o, RDFS.domain, r))
    for d in list(g.objects(o, RDFS.domain)):
        g.add((s, RDFS.range, d))
    for r in list(g.objects(o, RDFS.range)):
        g.add((s, RDFS.domain, r))
g.serialize(EXPANDED_ONTOLOGY, format="turtle")

conforms, results_graph, results_text = validate(
    DATA.read_text(),
    shacl_graph=SHAPES.read_text(),
    ont_graph=EXPANDED_ONTOLOGY.read_text(),
    inference="rdfs",
    abort_on_first=False,
    allow_infos=False,
    allow_warnings=False,
    meta_shacl=False,
    advanced=False,
    js=False,
    debug=False,
)
print("Conforms:", conforms)
if not conforms:
    print("Validation failed")
    print(results_text)
    sys.exit(1)
