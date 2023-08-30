# Openrefine SPARQL reconciliation
Demonstration of how to reconcile your data with Kulturnav.org data using Docker, Fuseki and OpenRefine.

**NB!** After setting up this docker stuff, i remembered that you can just load a `RDF` file with the `grefine-rdf-extension` and start reconciling with OpenRefine 🙄. **But**, if the `rdf` file is huge, this method is probably alot faster. I hope...

## Requirements 

* Git (usually installed on most systems)
* Docker ([mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac)|[windows](https://hub.docker.com/editions/community/docker-ce-desktop-windows))
* Latest OpenRefine with [grefine-rdf-extension](https://github.com/stkenny/grefine-rdf-extension), -> [install instructions](https://github.com/stkenny/grefine-rdf-extension/wiki)

## Folder structure

* **csv** -> for data to be reconciled
* **rdf** -> data from Kulturnav.org
* **result** -> whatever you export from OpenRefine

## Install

```bash 
# Open the terminal and clone this repository in your preferred folder
git clone git@git.app.uib.no:uib-ub/kulturnav-reconciliation.git
cd kulturnav-reconciliation
```

## The data to be reconciled
Get your data as a csv file or any other file `OpenRefine` can import and save it in the `csv` folder. It could be an export from your library system or from an SPARQL Endpoint. 

Below is a query you could use to query [marcus.uib.no](http://marcus.uib.no) data using a [SPARQL Endpoint](http://sparql.ub.uib.no/dataset.html?tab=query&ds=/sparql). Download the result as a `csv` file.

```sparql
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX dbo: <http://dbpedia.org/ontology/>

SELECT ?uri ?name ?firstname ?lastname ?invertedname ?birthdate ?birthyear ?deathdate ?deathyear WHERE {
  GRAPH ?g {
    ?uri a foaf:Person ;
         foaf:name ?name ;
    	 foaf:firstName ?firstname ;
         foaf:familyName ?lastname .
    OPTIONAL { ?uri dbo:birthDate ?birthdate . }
    OPTIONAL { ?uri dbo:deathDate ?deathdate . }
    OPTIONAL { ?uri dbo:birthYear ?birthyear . }
    OPTIONAL { ?uri dbo:deathYear ?deathyear . }
    BIND(CONCAT(?lastname, ", ", ?firstname) AS ?invertedname)
  }
}
LIMIT 100
```
[Direct link to the query](http://sparql.ub.uib.no/dataset.html?tab=query&ds=/sparql#query=PREFIX+foaf%3A+%3Chttp%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2F%3E%0APREFIX+dbo%3A+%3Chttp%3A%2F%2Fdbpedia.org%2Fontology%2F%3E%0A%0ASELECT+%3Furi+%3Fname+%3Ffirstname+%3Flastname+%3Finvertedname+%3Fbirthdate+%3Fbirthyear+%3Fdeathdate+%3Fdeathyear+WHERE+%7B%0A++GRAPH+%3Fg+%7B%0A++++%3Furi+a+foaf%3APerson+%3B%0A+++++++++foaf%3Aname+%3Fname+%3B%0A++++%09+foaf%3AfirstName+%3Ffirstname+%3B%0A+++++++++foaf%3AfamilyName+%3Flastname+.%0A++++OPTIONAL+%7B+%3Furi+dbo%3AbirthDate+%3Fbirthdate+.+%7D%0A++++OPTIONAL+%7B+%3Furi+dbo%3AdeathDate+%3Fdeathdate+.+%7D%0A++++OPTIONAL+%7B+%3Furi+dbo%3AbirthYear+%3Fbirthyear+.+%7D%0A++++OPTIONAL+%7B+%3Furi+dbo%3AdeathYear+%3Fdeathyear+.+%7D%0A++++BIND(CONCAT(%3Flastname%2C+%22%2C+%22%2C+%3Ffirstname)+AS+%3Finvertedname)%0A++%7D%0A%7D%0ALIMIT+100)

## Download Kulturnav data
Choose what you want to download from Kulturnav.org. It could be every person, as in the example below, or just a dataset like [Fotografregisteret (Norge) (Preus museum)](http://kulturnav.org/508197af-6e36-4e4f-927c-79f8f63654b2
)

### Issues with Kulturnav RDF
Kulturnav have some issues with its RDF representation. The file will have one missing `prefix` (as off february 2019). Manually change "j.0" to "knav-property".

There might be other issues with the data, some exports are just invalid `RDF` 😱. Fuseki will complain when the data is loaded. Report the issue to [Kulturnav.org](http://kulturnav.org/info/contact) and it will all get better with time 😊.

```bash
# Simples download using terminal and curl
curl http://kulturnav.org/exportRdfxml/search/entityType:Person -o rdf/.
```

## Start fuseki

**NB!** the `docker-entrypoint.sh` file only loads `.rdf` into Fuseki, but the file can easily be adjusted to load `.ttl` or other serializations.

```bash
# Build the Fuseki image
docker build -t knav-fuseki .

# Start the container with the data you have downloaded from Kulturnav.org
docker run -p 3031:3030 --name knav-fuseki --mount type=bind,source=$(pwd)/rdf/,target=/staging/data/ knav-fuseki

# If the container don't start you can run det following commands or use Kitematic
docker stop knav-fuseki
docker rm knav-fuseki
```

Fuseki will warn about Bad URIs and about some text not being UTF-8. Should load though.

```bash
WARN  [line: 539240, col: 163] {W107} Bad URI: <https://dea.digar.ee/cgi-bin/dea?a=q&r=1&results=1&txf=txTA&txq=%22Christin%2c+Hans%22&taq=Christin%2c+Hans> Code: 1/PERCENT_ENCODING_SHOULD_BE_UPPERCASE in QUERY: Percent-escape sequences should use uppercase.
...
WARN  [line: 2995949, col: 234] {W131} String not in Unicode Normal Form C: "Claes Gustaf Belinfante Östberg, född 17 juli 1852 (Svenska släktkalendern 1914) svensk-norsk.  År 1882 konsul i Messina på Sicilien, generalkonsul i Valparaiso, Peru 1888-1893 (Mörner 1965)."
WARN  [line: 2995977, col: 741] {W131} String not in Unicode Normal Form C: "Claes Gustaf Belinfante Östberg, född 17 juli 1852 (Svenska släktkalendern 1914) svensk-norsk. År 1882 konsul i Messina på Sicilien, generalkonsul i Valparaiso, Peru 1888-1893 (Mörner 1965). Har även varit det i Alexandria. Var i Denver 1899 (Vestkusten, Number 32, 10 August 1899 ). År 1910 var han bosatt i Rom (Corren 28 juli 1910) Son till brukspatron Gustaf Östberg och Anne Louise Grill. Bror till Petter och Gustaf Fredrik Östberg, grundadare av moderata samlingspartiet. Gift 1880 med Anita Elena Belinfante (född 1849) från Chile som dog 1881. Gift för andra gången 1901 med Amy Francis Lucas Belinfante (född 1866). (Svenska släktkalendern 1914)"
```

Hopefully the endpoint is up and running at [http://localhost:3031/](http://localhost:3031/) 🚀.

## Run OpenRefine 
Start OpenRefine, make a new project based on the data you want to reconcile against Kulturnav.org.

Add `localhost:3031` as the SPARQL endpoint. You will reconcile against `foaf:name` and probably `http://kulturnav.org/schema/property/entity.fullCaption`. More information: https://github.com/stkenny/grefine-rdf-extension/wiki/Example-SPARQL-Endpoint-Reconciliation.

The example SPARQL query constructed a new variable or column with the inverted name. This follows the Kulturnav way of using `foaf:name`. Marcus.uib.no does not invert the names on the `foaf:name` property. A variable the follows Kulturnav `entity.fullCaption` could also be constructed. Adding birthyear and deathyear should increase the number of full matches.

## Using the result

When OpenRefine is done, you need to go throught the suggested matches. After that you need to get the Kulturnav.org URI. On the reconciled column go to `Edit column` -> `Add column based on this column...`. In the dialogue box replace `value` with `cell.recon.candidates[0].id`. Now you have a column with the Kulturnav.org URIs.

If you want to export the result as RDF, use the `Edit RDF sceleton` function and build a `owl:sameAs` relation. Or you could export the wanted columns as `csv` for further processing.

```
<http://data.ub.uib.no/instance/person/34f7f312-7224-4625-891c-3acf437cad11> owl:sameAs <http://kulturnav.org/b6d2f525-e423-40ad-b948-ec63d59f22d9> .
```
