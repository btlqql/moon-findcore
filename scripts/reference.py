"""Independent Python standard library oracles; deterministic synthetic data."""
import csv, datetime, hashlib, heapq, io, json, math, random, subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
random.seed(20261005)
def run(request):
    result = subprocess.run(['node',str(root/'_build/js/debug/build/cmd/main/main.js'),'-'],
        input=json.dumps(request),capture_output=True,text=True,encoding='utf-8',timeout=30)
    if result.returncode: raise RuntimeError(result.stdout or result.stderr)
    return json.loads(result.stdout)

docs = [{'id':str(i),'fields':{'text':' '.join(random.choice(['alpha','beta','gamma']) for _ in range(random.randint(1,20)))}} for i in range(30)]
result = run({'documents':docs,'queries':['alpha'],'limit':100})
lengths = [len(d['fields']['text'].split()) for d in docs]
frequencies = [d['fields']['text'].split().count('alpha') for d in docs]
df = sum(f>0 for f in frequencies); avg = sum(lengths)/len(docs)
idf = math.log(1+(len(docs)-df+0.5)/(df+0.5))
scores = {str(i):idf*f*2.2/(f+1.2*(0.25+0.75*lengths[i]/avg)) for i,f in enumerate(frequencies) if f}
for hit in result['results'][0]['hits']: assert abs(scores[hit['id']]-hit['score']) < 1e-12
reloaded = run({'snapshot':result['snapshot'],'queries':['alpha'],'limit':100})
assert result['results'] == reloaded['results']
hits = result['results'][0]['hits']
assert {h['id'] for h in hits} == set(scores)
for a,b in zip(hits,hits[1:]):
    assert scores[a['id']] + 1e-12 >= scores[b['id']]
ties = run({'documents':[{'id':i,'fields':{'text':'alpha'}} for i in ['z','b','a']], 'queries':['alpha']})
assert [h['id'] for h in ties['results'][0]['hits']] == ['a','b','z']
print('Independent BM25 formula: 30 documents, ranking and snapshot reload passed')
