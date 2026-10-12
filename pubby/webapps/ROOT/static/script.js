document.addEventListener('DOMContentLoaded', init);

function init() {
    initLongLiterals();
    loadRandomResources();
}

function initLongLiterals() {
    const spans = document.querySelectorAll('span.literal');
    spans.forEach((span, idx) => {
        const text = span.textContent;
        if (!text || text.length < 300) return;
        const match = text.match(/([\s\S]{150}[\s\S]*? )([\s\S]*)/);
        if (!match) return;
        span.textContent = match[1] + ' ... ';
        const link = document.createElement('a');
        link.href = 'javascript:void(0)';
        link.textContent = '\u00BBmore\u00BB';
        link.className = 'expander';
        span._fullText = text;
        link.addEventListener('click', () => {
            span.textContent = span._fullText;
        });
        span.appendChild(link);
    });
}

function loadRandomResources() {
    const container = document.getElementById('random-list');
    if (!container) return;
    const endpoint = 'http://localhost:3030/ceribouchetiflorDS/query?query=';
    const sparql = `PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX ex: <http://example.org/>
SELECT DISTINCT ?s ?label WHERE {
    {
        SELECT ?s ?label WHERE {
            ?s rdf:type ex:Person ;
               rdfs:label ?label
        }
        LIMIT 3
    }
    UNION
    {
        SELECT ?s ?label WHERE {
            ?s rdf:type ex:Show ;
               rdfs:label ?label
        }
        LIMIT 3
    }
} ORDER BY RAND()`;

    fetch(endpoint + encodeURIComponent(sparql) + '&format=json', {
        method: 'GET',
        mode: 'cors', // Enable CORS
        headers: {
            'Accept': 'application/json'
        }
    })
    .then(res => res.json())
    .then(data => {
        // Rest of the code remains the same
        data.results.bindings.forEach(b => {
            const col = document.createElement('div'); col.className = 'col';
            const card = document.createElement('div'); card.className = 'card h-100';
            const body = document.createElement('div'); body.className = 'card-body text-center';
            const link = document.createElement('a');
            link.href = b.s.value;
            link.textContent = b.label.value;
            link.className = 'card-link';
            body.appendChild(link);
            card.appendChild(body);
            col.appendChild(card);
            container.appendChild(col);
        });
    })
    .catch(err => console.error('Random resources load error:', err));
}


function showAllMetadata(name) {
    const container = document.getElementById(name);
    if (!container) return;
    container.querySelectorAll('table').forEach(tbl => tbl.style.display = 'block');
}