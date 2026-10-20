#!/usr/bin/env python3
"""画面项目定义 / API 请求 JSON / 画面一览 与 90-db-design.md DDL 一致性比对脚本。

用法（在仓库根目录执行）：
    python3 docs/design/30-review/tools/screen_ddl_audit.py [输出 JSON 路径]

默认输出到 ./screen_ddl_audit.json，并在标准输出打印汇总。
结果为候选项，需人工复核（会包含引用子表名、显示用 code/name 等误报）。
"""
import sys
import re,os,json,glob,collections
B=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..')+'/'
doms=sorted(d for d in os.listdir(B) if re.match(r'\d\d-',d) and d[:2]<'20' and d!='00-common')
COMMON={'id':'BIGINT','tenant_id':'BIGINT','company_id':'BIGINT','created_at':'TIMESTAMPTZ','created_by':'BIGINT','updated_at':'TIMESTAMPTZ','updated_by':'BIGINT','version':'INT','remark':'VARCHAR(500)','ext_data':'JSONB','deleted':'BOOLEAN','is_deleted':'BOOLEAN'}
def norm(t):
    t=t.upper().replace(' ','')
    t=re.sub(r'^INTEGER','INT',t); t=re.sub(r'^INT4$','INT',t);t=t.replace('INT8','BIGINT').replace('INT2','SMALLINT')
    t=t.replace('BOOL','BOOLEAN').replace('BOOLEANEAN','BOOLEAN').replace('CHARACTERVARYING','VARCHAR').replace('DECIMAL','NUMERIC')
    t=t.replace('TIMESTAMPWITHTIMEZONE','TIMESTAMPTZ')
    m=re.match(r'(VARCHAR\(\d+\)|NUMERIC\(\d+,\d+\)|CHAR\(\d+\)|BIGINT|SMALLINT|INT|DATE|TIMESTAMPTZ|TIMESTAMP|BOOLEAN|TEXT|JSONB|BYTEA|TIME|UUID|INET|NUMERIC)',t)
    return m.group(1) if m else None
tables={};tdom={};colidx=collections.defaultdict(list)
for d in doms:
    f=B+d+'/90-db-design.md'
    if not os.path.exists(f):continue
    L=open(f).read().split('\n');i=0
    while i<len(L):
        m=re.match(r'\s*CREATE TABLE (?:IF NOT EXISTS )?([a-z0-9_]+)',L[i])
        if m:
            tn=m.group(1);cols={};j=i+1
            while j<len(L) and not re.match(r'\s*\);',L[j]):
                line=re.sub(r'--.*','',L[j]);depth=0;buf='';parts=[]
                for ch in line:
                    if ch=='(':depth+=1
                    if ch==')':depth-=1
                    if ch==',' and depth==0: parts.append(buf);buf=''
                    else: buf+=ch
                parts.append(buf)
                for p in parts:
                    c=re.match(r'\s*([a-z_][a-z0-9_]*)\s+([A-Za-z]+(?:\s*\([\d, ]+\))?(?:\s+WITH TIME ZONE)?(?:\[\])?)',p)
                    if c and c.group(1).upper() not in('CONSTRAINT','PRIMARY','UNIQUE','FOREIGN','CHECK','EXCLUDE') and c.group(1) not in('constraint',):
                        cols.setdefault(c.group(1),(norm(c.group(2)) or c.group(2),j+1))
                j+=1
            tables[tn]=(cols,f.replace(B,''),i+1);tdom[tn]=d
            for c,(t,ln) in cols.items(): colidx[c].append((tn,t,ln))
            i=j
        i+=1
def snake(s):return re.sub(r'(?<=[a-z0-9])([A-Z])',r'_\1',s).lower()
issues=[] # dict(dom,sev,kind,...)
alias={}
screen_ids_spec=collections.defaultdict(list); itemdef_ids=set()
phase=[]
for d in doms:
    dt=[t for t in tables if tdom[t]==d]
    for f in sorted(glob.glob(B+d+'/0[1-9]-*.md')):
        rel=f.replace(B,'');L=open(f).read().split('\n')
        for k,l in enumerate(L):
            if re.search(r'Phase\s*[23]|二期|三期|Phase2|Phase3',l) and 'SCR-' in l: phase.append((d,rel,k+1,l.strip()[:160]))
            for s in re.findall(r'^\|\s*(SCR-[A-Z]+-\d+)\s*\|',l): screen_ids_spec[s].append((rel,k+1))
        k=0
        while k<len(L):
            l=L[k]
            if l.startswith('|') and re.search(r'DB\s*項目|DB\s*项目|DB列|DB 列|DB カラム',l):
                hdr=[h.strip() for h in l.strip().strip('|').split('|')]
                def ix(p):
                    for n,h in enumerate(hdr):
                        if re.search(p,h):return n
                iid=ix(r'項目\s*ID|项目\s*ID|項目ID');ity=ix(r'型');idb=ix(r'DB')
                # context table
                ctx=[];
                for b in range(k-1,max(0,k-40),-1):
                    for t in re.findall(r'`?([a-z]{2,4}_[a-z0-9_]+)`?',L[b]):
                        if t in tables:ctx.append(t)
                    if L[b].startswith('#') and ctx:break
                    if L[b].startswith('##') : 
                        for t in re.findall(r'([a-z]{2,4}_[a-z0-9_]+)',L[b]):
                            if t in tables:ctx.append(t)
                        break
                sec=next((L[b] for b in range(k,0,-1) if L[b].startswith('#')),'')
                for s in re.findall(r'SCR-[A-Z]+-\d+',sec):itemdef_ids.add(s)
                k+=2
                while k<len(L) and L[k].startswith('|'):
                    c=[x.strip() for x in L[k].strip().strip('|').split('|')]
                    if idb is None or idb>=len(c):k+=1;continue
                    dbc=c[idb];itm=c[iid] if iid is not None and iid<len(c) else '';ty=c[ity] if ity is not None and ity<len(c) else ''
                    names=re.findall(r'`([^`]+)`',dbc) or ([dbc] if re.match(r'^[a-z_][a-z0-9_.]*$',dbc) else [])
                    names=[n for n in names if re.match(r'^[a-z_][a-z0-9_]*(\.[a-z_][a-z0-9_]*)?$',n)]
                    if not names and dbc not in('—','-','','－','―') and not re.search(r'なし|無し|计算|計算|派生|算出|画面|画面のみ|—',dbc):
                        pass
                    itms=re.findall(r'`([A-Za-z0-9_.]+)`',itm)
                    for n in names:
                        tb=None
                        if '.' in n: tb,n=n.split('.',1)
                        if len(itms)==1 and len(names)==1: alias[itms[0]]=n
                        cand=[]
                        if tb and tb in tables: cand=[tb]
                        else: cand=[t for t in ctx if t in tables]
                        found=[(t,tables[t][0][n]) for t in cand if n in tables[t][0]]
                        if not found and n in COMMON: k2=None;continue
                        if not found:
                            dfound=[x for x in colidx.get(n,[]) if tdom[x[0]]==d]
                            afound=colidx.get(n,[])
                            if not dfound and not afound:
                                issues.append(dict(dom=d,sev='S1' if ('○' in L[k]) else 'S2',kind='a',src=f'{rel}:{k+1}',item=itm,col=n,ctx=cand,detail='DDL 中任何表都没有该列'))
                                continue
                            if cand and not tb:
                                issues.append(dict(dom=d,sev='S2',kind='a2',src=f'{rel}:{k+1}',item=itm,col=n,ctx=cand,detail='上下文表中无此列，仅在其他表存在: '+', '.join(f'{x[0]}' for x in (dfound or afound)[:4]),ev=[(x[0],x[2]) for x in (dfound or afound)[:3]]))
                            found=[(x[0],(x[1],x[2])) for x in (dfound or afound)]
                        st=norm(ty) if ty and len(names)==1 else None
                        if st:
                            ts=set(f2[1][0] for f2 in found)
                            if st not in ts:
                                ok=False
                                for t2 in ts:
                                    if t2 and st and t2.split('(')[0]==st.split('(')[0] and '(' not in st: ok=True
                                if not ok:
                                    t0,(tt,ln)=found[0]
                                    issues.append(dict(dom=d,sev='S2',kind='b',src=f'{rel}:{k+1}',item=itm,col=n,detail=f'画面 {ty} ↔ DDL {t0}.{n} {tt}',ev=[(t0,ln)]))
                    k+=1
                continue
            k+=1
# API json keys
apiiss=[]
for d in doms:
    dcols=set(c for t in tables if tdom[t]==d for c in tables[t][0])
    allc=set(colidx)
    for f in sorted(glob.glob(B+d+'/*.md')):
        if '/90-' in f:continue
        rel=f.replace(B,'');L=open(f).read().split('\n');k=0
        while k<len(L):
            if L[k].strip()=='```json':
                pre='\n'.join(L[max(0,k-6):k]);j=k+1
                while j<len(L) and L[j].strip()!='```':j+=1
                body=L[k+1:j]
                isreq=re.search(r'\b(POST|PUT|PATCH)\b',pre) and not re.search(r'レスポンス|Response|response|応答|响应',pre) and not (body and re.search(r'"code"',' '.join(body[:2])))
                if isreq:
                    for o,bl in enumerate(body):
                        m=re.match(r'\s*"([A-Za-z0-9_]+)"\s*:\s*(.)',bl)
                        if not m:continue
                        key,v=m.group(1),m.group(2)
                        if v in '[{':continue
                        sn=alias.get(key) or snake(key)
                        cands={sn,re.sub(r'_ids?$','_id',sn),sn+'_id',sn+'_code',re.sub(r'^is_','',sn),'is_'+sn,sn.replace('_ids','_id')}
                        if cands & allc or sn in COMMON:continue
                        if re.search(r'^(reason|comment|confirm|force|password|captcha|token|page|size|sort|keyword|ids|action|opinion|dry|async|file|attachment)',sn):continue
                        apiiss.append(dict(dom=d,src=f'{rel}:{k+2+o}',key=key,sn=sn))
                k=j
            k+=1
# screen list
SL=B+'20-matrix/02-screen-list.md';slist={}
for n,l in enumerate(open(SL).read().split('\n')):
    m=re.match(r'\|\s*(SCR-[A-Z]+-\d+)\s*\|\s*([^|]*)\|',l)
    if m: slist[m.group(1)]=(m.group(2).strip(),n+1,l)
# unused
used=collections.defaultdict(set)
for d in doms:
    txt=''.join(open(f).read() for f in glob.glob(B+d+'/*.md') if '/90-' not in f)
    txt+=open(B+'20-matrix/09-api-list.md').read() if False else ''
    used[d]=txt
unused=collections.Counter();tot=collections.Counter();unused_ex=collections.defaultdict(list)
def camel(s):p=s.split('_');return p[0]+''.join(x.title() for x in p[1:])
for t,(cols,f,ln) in tables.items():
    d=tdom[t]
    for c,(ty,l2) in cols.items():
        if c in COMMON:continue
        tot[d]+=1
        if c not in used[d] and camel(c) not in used[d]:
            unused[d]+=1; unused_ex[d].append(f'{t}.{c}')
json.dump(dict(issues=issues,api=apiiss,slist=slist,spec={k:v for k,v in screen_ids_spec.items()},itemdef=sorted(itemdef_ids),phase=phase,unused=unused,tot=tot,unused_ex=unused_ex,ntables=len(tables)),open(sys.argv[1] if len(sys.argv)>1 else 'screen_ddl_audit.json','w'),ensure_ascii=False,indent=0)
print(len(tables),collections.Counter((i['dom'],i['kind']) for i in issues),collections.Counter(a['dom'] for a in apiiss),len(slist),len(screen_ids_spec),len(phase),dict(unused),dict(tot))
