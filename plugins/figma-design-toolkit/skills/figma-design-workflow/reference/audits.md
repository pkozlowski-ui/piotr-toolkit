# Audit scripts — figma-design-workflow

> **Load when:** running the token-compliance audit on a component, the instance-ratio audit on a
> screen, or cataloging a design system on first contact with a new Figma file.
> The hard gate (`gateScreen`) stays in `SKILL.md` → "Post-build quality checklist".

## Token compliance audit script

Run this after building any DS component to verify zero hardcoded values:

```javascript
// Replace 'MyComponent' with the component's exact name
const comp = figma.currentPage.findOne(n => n.name === 'MyComponent');
const issues = [];
const SPACING_VALS = new Set([4,8,12,16,20,24,32,40,48,64]);
const RADIUS_VALS  = new Set([4,6,8,12,16,9999]);

comp.findAll(() => true).forEach(n => {
  ['fills','strokes'].forEach(kind => {
    const paints = n[kind];
    if (!paints || paints === figma.mixed || paints.length === 0) return;
    paints.forEach((p, i) => {
      if (p.type !== 'SOLID' || p.opacity === 0) return;
      const bound = n.boundVariables?.[kind]?.[i]?.type === 'VARIABLE_ALIAS';
      if (!bound) issues.push(`${n.name} [${n.id}]: hardcoded ${kind} #${
        ['r','g','b'].map(c => Math.round(p.color[c]*255).toString(16).padStart(2,'0')).join('')
      }`);
    });
  });
  if (n.type === 'TEXT') {
    if (!n.textStyleId || n.textStyleId === figma.mixed)
      issues.push(`${n.name} [${n.id}]: missing text style (${n.fontSize}px)`);
  }
  ['paddingTop','paddingRight','paddingBottom','paddingLeft','itemSpacing'].forEach(prop => {
    const val = n[prop];
    if (typeof val !== 'number' || val === 0) return;
    if (n.boundVariables?.[prop]?.type !== 'VARIABLE_ALIAS')
      issues.push(`${n.name} [${n.id}]: hardcoded ${prop}=${val}${SPACING_VALS.has(val) ? '' : ' ⚠️ off-scale'}`);
  });
  const crBound = n.boundVariables?.cornerRadius?.type === 'VARIABLE_ALIAS';
  const anyCornerBound = ['topLeftRadius','topRightRadius','bottomLeftRadius','bottomRightRadius']
    .some(p => n.boundVariables?.[p]?.type === 'VARIABLE_ALIAS');
  if (!crBound && !anyCornerBound) {
    const cr = n.cornerRadius;
    if (typeof cr === 'number' && cr > 0)
      issues.push(`${n.name} [${n.id}]: hardcoded cornerRadius=${cr}${RADIUS_VALS.has(cr) ? '' : ' ⚠️ off-scale'}`);
  }
});
return { issueCount: issues.length, issues };
// issueCount: 0 → ready to ship. Anything else → fix before closing the session.
```

> **For SCREEN-level audits, treat each INSTANCE as opaque** (count it, don't recurse into it).
> `findAll(()=>true)` descends into DS components and flags their internal frames (NavRail, AppTopBar)
> as violations — you'll see a false ~70% where the real composition is 100%. Use a manual walk:

```javascript
// Instance-ratio audit for a screen — instance = opaque
function instanceRatioAudit(screen){
  const LAYOUT=/section|row|col|cols|container|content|wrapper|wrap|group|stack|list|grid|scroll|panel|bar$|spacer|footer|filter|head|header|body|main|kpi|table|card|drawer/i;
  const violations=[]; let instances=0, layoutFrames=0;
  (function walk(n){ for(const c of (n.children||[])){
    if(c.type==='INSTANCE'){ instances++; continue; }            // opaque — never recurse
    if(c.type==='TEXT'||c.type==='VECTOR'||c.type==='RECTANGLE'||c.type==='SLOT') continue;
    if(c.type==='FRAME'){
      if(LAYOUT.test(c.name)){ layoutFrames++; }
      else { const textChild=c.findOne?.(x=>x.type==='TEXT'),
                   hasFill=Array.isArray(c.fills)&&c.fills.some(f=>f.visible!==false&&f.opacity!==0),
                   hasStroke=Array.isArray(c.strokes)&&c.strokes.length>0;
             if((c.width<240&&c.height<80)||textChild||hasFill||hasStroke) violations.push(c.name); }
      walk(c);
    }
  }})(screen);
  const total=instances+violations.length;
  return { ratio:(total?Math.round(instances/total*100):100)+'%', pass: total? instances/total>=0.95 : true, instances, layoutFrames, violations };
}
// pass:true (≥95%) → ship. Replace violations with DS instances otherwise.
```

---

## How to catalog a new design system

On first contact with a new Figma file, run this script and save the result to memory:

```javascript
await figma.loadAllPagesAsync();
const pages = figma.root.children.map(p => ({ name: p.name, id: p.id }));

// Find first meaningful page (skip pages with '---' prefix)
const refPage = figma.root.children.find(p => !p.name.startsWith('---') && p.children.length > 0);
await figma.setCurrentPageAsync(refPage);

// File conventions
const frame = refPage.children[0];
const frameWidth = frame?.width;

// Color variables
const vars = await figma.variables.getLocalVariablesAsync();
const colorVars = vars.filter(v => v.resolvedType === 'COLOR')
  .map(v => ({ name: v.name, id: v.id }));

// Components from instances on the reference page
const instances = refPage.findAll(n => n.type === 'INSTANCE');
const compMap = {};
for (const inst of instances.slice(0, 30)) {
  const mc = await inst.getMainComponentAsync();
  if (mc && mc.key) compMap[mc.key] = { name: mc.name, key: mc.key };
}

return {
  pages: pages.map(p => p.name),
  frameWidth,
  colorVarCount: colorVars.length,
  colorSample: colorVars.slice(0, 15),
  componentSample: Object.values(compMap)
};
// → Copy the result to memory/ as a reference for this file
```

---
