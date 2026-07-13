# RAG 파이프라인과 FHE 적용 파이프라인

## 1. 기존 RAG 파이프라인

핵심 흐름만 표시한다.

![기존 RAG 흐름](rag-standard-flow.svg)

```xml
<mxfile host="app.diagrams.net" modified="2026-07-03T00:00:00.000Z" agent="Codex" version="26.0.0">
  <diagram id="standard-rag-flow" name="기존 RAG 흐름">
    <mxGraphModel dx="1200" dy="720" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1200" pageHeight="720" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="index_lane" value="인덱싱" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;fontColor=#334155;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="30" y="40" width="790" height="270" as="geometry" />
        </mxCell>
        <mxCell id="query_lane" value="검색" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#bfdbfe;fontColor=#1d4ed8;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="30" y="350" width="790" height="310" as="geometry" />
        </mxCell>
        <mxCell id="generation_lane" value="생성" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff7ed;strokeColor=#fed7aa;fontColor=#9a3412;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="860" y="210" width="300" height="450" as="geometry" />
        </mxCell>
        <mxCell id="docs" value="문서" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#64748b;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="60" y="105" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="loader" value="Loader" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#2563eb;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="245" y="105" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="chunker" value="Chunker" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#2563eb;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="430" y="105" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="doc_embed" value="Embedding" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e0f2fe;strokeColor=#0284c7;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="615" y="105" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="vectordb" value="Vector DB" style="shape=cylinder3d;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#e0f2fe;strokeColor=#0284c7;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="615" y="205" width="145" height="85" as="geometry" />
        </mxCell>
        <mxCell id="user_query" value="쿼리" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#64748b;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="60" y="430" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="query_embed" value="Query Embedding" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e0f2fe;strokeColor=#0284c7;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="245" y="430" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="similarity" value="Similarity Search" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="430" y="430" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="topk" value="Top-k" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="615" y="430" width="145" height="70" as="geometry" />
        </mxCell>
        <mxCell id="prompt" value="Prompt Builder" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffedd5;strokeColor=#ea580c;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="930" y="285" width="160" height="80" as="geometry" />
        </mxCell>
        <mxCell id="llm" value="LLM" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffedd5;strokeColor=#ea580c;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="930" y="425" width="160" height="80" as="geometry" />
        </mxCell>
        <mxCell id="answer" value="응답" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#64748b;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="930" y="565" width="160" height="70" as="geometry" />
        </mxCell>
        <mxCell id="e1" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="docs" target="loader">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e2" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="loader" target="chunker">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e3" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="chunker" target="doc_embed">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e4" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="doc_embed" target="vectordb">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e5" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="user_query" target="query_embed">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e6" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="query_embed" target="similarity">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e7" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="vectordb" target="similarity">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="688" y="330" />
              <mxPoint x="503" y="330" />
            </Array>
          </mxGeometry>
        </mxCell>
        <mxCell id="e8" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="similarity" target="topk">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e9" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#ea580c;fontColor=#9a3412;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="topk" target="prompt">
          <mxGeometry relative="1" as="geometry">
            <Array as="points">
              <mxPoint x="820" y="465" />
              <mxPoint x="820" y="325" />
            </Array>
          </mxGeometry>
        </mxCell>
        <mxCell id="e10" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#ea580c;fontColor=#9a3412;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="prompt" target="llm">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e11" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#ea580c;fontColor=#9a3412;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="llm" target="answer">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

## 2. 동형암호 적용 RAG 파이프라인

기존 RAG에서 암호화가 추가되는 지점만 표시한다.

![FHE 적용 RAG 흐름](rag-fhe-flow.svg)

```xml
<mxfile host="app.diagrams.net" modified="2026-07-03T00:00:00.000Z" agent="Codex" version="26.0.0">
  <diagram id="fhe-rag-flow" name="FHE 적용 RAG 흐름">
    <mxGraphModel dx="1500" dy="760" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1500" pageHeight="760" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <mxCell id="plaintext_lane" value="평문 구간" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f8fafc;strokeColor=#cbd5e1;fontColor=#334155;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="30" y="40" width="390" height="680" as="geometry" />
        </mxCell>
        <mxCell id="encrypted_lane" value="암호문 구간" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f3ff;strokeColor=#ddd6fe;fontColor=#5b21b6;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="450" y="40" width="470" height="680" as="geometry" />
        </mxCell>
        <mxCell id="generation_lane" value="생성" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fff7ed;strokeColor=#fed7aa;fontColor=#9a3412;fontStyle=1;verticalAlign=top;align=left;spacingLeft=12;spacingTop=8;" vertex="1" parent="1">
          <mxGeometry x="930" y="40" width="530" height="680" as="geometry" />
        </mxCell>
        <mxCell id="docs" value="문서 코퍼스" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#64748b;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="70" y="105" width="130" height="58" as="geometry" />
        </mxCell>
        <mxCell id="chunker" value="Chunker" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#eff6ff;strokeColor=#2563eb;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="95" width="130" height="78" as="geometry" />
        </mxCell>
        <mxCell id="doc_embed" value="Embedding" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e0f2fe;strokeColor=#0284c7;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="250" y="210" width="130" height="70" as="geometry" />
        </mxCell>
        <mxCell id="doc_encrypt" value="FHE Encrypt" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ecfdf5;strokeColor=#059669;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="500" y="205" width="140" height="78" as="geometry" />
        </mxCell>
        <mxCell id="enc_vectordb" value="Encrypted Vector DB" style="shape=cylinder3d;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;fillColor=#f5f3ff;strokeColor=#7c3aed;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="710" y="185" width="160" height="110" as="geometry" />
        </mxCell>
        <mxCell id="query" value="사용자 쿼리" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#64748b;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="70" y="430" width="130" height="58" as="geometry" />
        </mxCell>
        <mxCell id="query_embed" value="Query Embedding" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#e0f2fe;strokeColor=#0284c7;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="250" y="420" width="130" height="78" as="geometry" />
        </mxCell>
        <mxCell id="query_encrypt" value="FHE Encrypt" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ecfdf5;strokeColor=#059669;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="500" y="420" width="140" height="78" as="geometry" />
        </mxCell>
        <mxCell id="encrypted_similarity" value="Encrypted Similarity" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="710" y="410" width="160" height="96" as="geometry" />
        </mxCell>
        <mxCell id="scores" value="Encrypted Scores" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f3ff;strokeColor=#7c3aed;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="710" y="545" width="160" height="70" as="geometry" />
        </mxCell>
        <mxCell id="decrypt_rank" value="Decrypt + Rank" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ecfdf5;strokeColor=#059669;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="950" y="545" width="140" height="70" as="geometry" />
        </mxCell>
        <mxCell id="selected_chunks" value="Selected Chunks" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#f0fdf4;strokeColor=#16a34a;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="1125" y="545" width="140" height="70" as="geometry" />
        </mxCell>
        <mxCell id="prompt" value="Prompt Builder" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffedd5;strokeColor=#ea580c;fontColor=#0f172a;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="1300" y="545" width="140" height="70" as="geometry" />
        </mxCell>
        <mxCell id="llm" value="LLM" style="rounded=1;whiteSpace=wrap;html=1;fillColor=#ffedd5;strokeColor=#ea580c;fontColor=#0f172a;" vertex="1" parent="1">
          <mxGeometry x="1300" y="650" width="140" height="55" as="geometry" />
        </mxCell>
        <mxCell id="e1" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="docs" target="chunker">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e2" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="chunker" target="doc_embed">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e3" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="doc_embed" target="doc_encrypt">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e4" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#7c3aed;fontColor=#5b21b6;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="doc_encrypt" target="enc_vectordb">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e5" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="query" target="query_embed">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e6" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#334155;fontColor=#334155;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="query_embed" target="query_encrypt">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e7" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#7c3aed;fontColor=#5b21b6;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="query_encrypt" target="encrypted_similarity">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e8" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#7c3aed;fontColor=#5b21b6;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="enc_vectordb" target="encrypted_similarity">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e9" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#7c3aed;fontColor=#5b21b6;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="encrypted_similarity" target="scores">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e10" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#059669;fontColor=#047857;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="scores" target="decrypt_rank">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e11" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#059669;fontColor=#047857;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="decrypt_rank" target="selected_chunks">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e12" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#ea580c;fontColor=#9a3412;exitX=1;exitY=0.5;entryX=0;entryY=0.5;" edge="1" parent="1" source="selected_chunks" target="prompt">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="e13" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=block;endFill=1;strokeColor=#ea580c;fontColor=#9a3412;exitX=0.5;exitY=1;entryX=0.5;entryY=0;" edge="1" parent="1" source="prompt" target="llm">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```
