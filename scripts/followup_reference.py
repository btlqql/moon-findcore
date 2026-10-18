"""Independent follow-up oracles over synthetic deterministic inputs."""
import collections,copy,hashlib,json,math,random,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
random.seed(20261018)
def run(request, error=False):
    result=subprocess.run(['node',str(root/'_build/js/debug/build/cmd/main/main.js'),'-'],input=json.dumps(request),capture_output=True,text=True,encoding='utf-8',timeout=60)
    if error:
        assert result.returncode==1,(result.returncode,result.stdout); return
    assert result.returncode in (0,2),(result.returncode,result.stdout,result.stderr)
    return json.loads(result.stdout)

for _ in range(20):
    docs=[{'id':str(i),'fields':{'text':random.choice(['moon','sun'])}} for i in range(8)]
    revised=copy.deepcopy(docs); revised[0]['fields']['text']='moon' if docs[0]['fields']['text']=='sun' else 'sun'
    old={'documents':docs,'queries':['moon'],'limit':100}; new={'documents':revised,'queries':['moon'],'limit':100}
    report=run({'operation':'compare','old':old,'new':new})['queries'][0]
    a={d['id'] for d in docs if d['fields']['text']=='moon'}; b={d['id'] for d in revised if d['fields']['text']=='moon'}
    assert set(report['added'])==b-a and set(report['removed'])==a-b
    assert report['before_total']==len(a) and report['after_total']==len(b)
print('Search regression: 20 independent corpus membership deltas passed')
