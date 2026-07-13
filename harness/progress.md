# 진행 상황

> 아래에는 삭제된 과거 구현과 당시 결정을 기록한 항목도 있다. 현재 설계는
> `session-handoff.md`와 `docs/1-0. security-architecture-index.md`가 우선한다. 특히 단일 Reveal
> Authority, 완성 secret key와 선택적 smartphone step-up 기록은 PC·스마트폰 2-of-2 설계로
> 대체되었다.

## 현재 상태

- **최종 업데이트:** 2026-07-13
- **테스트:** 현재 제품 코드(`fhe/`), 테스트(`tests/`), 제품 스크립트(`scripts/`)를 제거한 상태라 `./init.sh` 검증 기준은 더 이상 통과하지 않는다.
- **상태:** 재개발을 위해 제품 코드를 제거하고 하네스/문서만 남긴 초기화 상태.
- **명칭:** 시스템 대표 명칭 = **FHE-Privacy 프라이버시 게이트웨이** (Python 패키지로 배포).
- **범위:** 외부 에이전트용 로컬 프라이버시 게이트웨이(MCP/secure gateway) 시스템.
- **비범위:** 웹서버, 채팅 UI, 자체 LLM provider loop, DB viewer, web_search.
- **다음 시작점:** 확정 설계의 구현 가능성 spike와 P0 문서/검증 하네스 재구축.

## 2026-07-13 보안 아키텍처 전체 기준 정리

- RAG를 제외한 아키텍처 문서를 새 설계 기준으로 정합화했다.
- 첫 외부 Agent 구현 대상을 Hermes로 확정했다. 지원 완료 표시는 adapter와 OpenShell E2E 검증 후로 유보한다.
- 채택한 핵심 경계:
  - Secure Gateway만 사용자 원문을 수신하고, 불확실하거나 실패하면 Agent 호출 전에 중단한다.
  - Hermes Agent 전체와 stateless Agent MCP Bridge를 OpenShell sandbox 안에 둔다.
  - Agent는 opaque, typed, session-bound handle과 허용된 공개 연산만 사용한다.
  - Privacy Core, Public Compute Worker, Reveal Coordinator, PC/phone partial authority와 Fusion Sink를
    서로 다른 권한 채널로 분리한다.
  - FHE secret은 PC와 스마트폰의 2-of-2 share로만 보관하고 완성된 secret key를 만들지 않는다.
  - plaintext는 두 장치가 참여한 뒤 승인된 PC terminal 또는 phone display Fusion Sink에서만 만든다.
  - reveal은 post-LLM terminal egress에서만 수행하며 Agent/history/tool로 되돌리지 않는다.
  - CKKS는 근사 수치, BFV/BGV는 exact integer, Boolean FHE는 exact predicate에 사용한다.
  - 주민등록번호 같은 exact identifier는 record별 AEAD와 2-of-2 threshold envelope로 보호한다.
  - 이름은 현재 제품의 PII 탐지·masking 대상에서 제외한다.
  - 초기 Vault는 메모리 기반이며 후속 영속화 기본안은 SQLite metadata + binary BLOB이다.
  - 초기 입력 범위는 text-only이며 attachment/OCR/audio/memory/tool plaintext는 차단한다.
- 기능 목록과 개발 계획은 전 항목 `not_started`인 재구축 기준으로 다시 작성했다.
- draw.io 원본을 2-of-2 구조에 맞췄고 내용이 오래된 SVG 산출물 3개는 삭제했다.
- 비개발자도 읽을 수 있도록 `docs/glossary.md`를 추가하고 주요 문서에 쉬운 설명을 넣었다.
- `docs/pii-detection-catalog.md`에 이름을 제외한 92개 탐지 후보를 정리했다.
- 문서 변경 30개를 `4da1145d` (`docs(fhe-privacy): revise privacy architecture`)로 커밋해
  `origin/main`에 푸시했다.
- 설계 상태이므로 구현 완료나 `./init.sh` 통과를 주장하지 않는다.

## 2026-07-13 개발 환경 상태

- `mise` 2026.7.5를 `~/.local/bin/mise`에 설치했다.
- `~/.zshrc`에 mise zsh activation을 추가하고 OpenShell `mise.toml`을 trust했다.
- 전체 15개 도구 설치를 시작했으나 사용자 요청으로 중단했다. 상태 기록 전 실행한
  `mise run pre-commit`이 누락 도구 설치를 자동으로 재개해 Rust와 Skaffold 설치까지 완료한 뒤
  다시 중단했다.
- 설치 완료: Python, Node, uv, kubectl, protoc, Helm, helm-docs, Syft, cargo-about,
  cargo-zigbuild, sccache, markdownlint-cli2.
- 추가 설치 완료: Rust 1.95.0, Skaffold 2.20.0.
- 미설치: Zig 0.14.1.
- 설치 프로세스가 종료됐음을 확인했다. `mise run pre-commit`의 실제 검사 단계는 완료되지 않았다.
  재개 시 Zig만 설치한 뒤 `mise doctor`와 pre-commit을 실행한다.

## 2026-07-13 Pre-LLM ingress 경계 확정

- 기존 기능 목록과 개발 계획을 구현 근거로 사용하지 않고 아키텍처를 문제별로 다시 검토하기 시작.
- 외부 Agent와 LLM을 비신뢰 영역으로 확정하고, 외부 Agent 전체를 OpenShell sandbox에서 실행하는
  방향을 채택.
- 첫 번째 문제인 pre-LLM Gateway 강제 경계를 확정:
  - Secure Gateway만 사용자 원문을 수신.
  - OpenShell Hermes Agent와 LLM에는 masked envelope만 전달.
  - PII 검출, 암호화, Vault 저장, masking 검증이 실패하거나 불확실하면 Agent를 호출하지 않음.
  - Gateway를 강제할 수 없는 Agent 연결은 secure-gateway 모드로 표시하지 않음.
- `docs/1-1. pre-llm-ingress.md`에 신뢰 경계, 정상 흐름, envelope 최소 계약, fail-closed 규칙,
  초기 지원 범위, OpenShell 조건, 완료 검증을 기록.
- `docs/1. architecture-component-flow.drawio`에 trusted host ingress와 OpenShell untrusted 영역,
  sole raw-input owner, masked-envelope-only 경로, fail-closed 중단 경로를 반영.
- `docs/1. architecture-component-flow.svg`를 최신 draw.io 원본에서 생성하고
  `docs/architecture-flow.md`의 깨진 링크를 새 파일명으로 수정.
- 다음 아키텍처 문제: stdio MCP bridge와 stateful Privacy Core의 프로세스/상태 배치.

## 2026-07-13 코드베이스 초기화

- 사용자 요청에 따라 제품 코드와 테스트를 제거.
- 유지:
  - `AGENTS.md`
  - `CLAUDE.md`
  - `README.md`
  - `docs/`
  - `feature_list.json`
  - `init.sh`
  - `progress.md`
  - `pyproject.toml`
  - `session-handoff.md`
  - `uv.lock`
  - `vendor/`
- 삭제:
  - `fhe/`
  - `tests/`
  - `scripts/`
- 결과:
  - 문서와 하네스는 남아 있음
  - 구현 코드 기준의 feature state는 초기화 필요
  - 다음 구현 전까지 검증 상태를 `passing`으로 주장할 수 없음

## 2026-07-03 프로젝트 재정의

- 새 프로젝트 위치: `/Users/giljong-in/Workspace/AGENTS/AgentOrigin/FHE-Privacy`
- 기존 FHE-Agent PoC에서 FHE/PII 핵심만 분리:
  - `fhe/client/`: FHEClient, profile store, bytes/base64 유틸
  - `fhe/engine/`: OpenFHE backend, subprocess backend, wire protocol
  - `fhe/server/fhe_ops.py`: 공개 컨텍스트 동형 연산 파사드
  - `fhe/server/masking.py`: 금액/수량/전화/이름 마스킹, SecretVault, RevealVault
  - FHE/PII 관련 테스트
- 제거/비포함:
  - FastAPI/uvicorn 서버
  - 자체 agent loop
  - Anthropic/OpenRouter provider 코드
  - WebSocket/프런트엔드
  - SQLite ledger/demo seed

## 2026-07-03 하네스/문서 갱신

- `AGENTS.md`, `CLAUDE.md`, `progress.md`, `session-handoff.md`, `init.sh`, `pyproject.toml`
  기준을 배포형 FHE-Privacy 런타임으로 갱신.
- 기존 docs 내용 제거.
- 새 문서 생성:
  - `docs/fhe-features.md`
  - `docs/fhe-development-plan.md`
  - `docs/architecture-flow.md`
  - `docs/distribution-guide.md`

## 2026-07-03 draw.io 다이어그램 전환

- `README.md` 목표 구조를 draw.io 원본 + SVG 표시로 전환.
- `docs/architecture-flow.md`의 전체 컴포넌트 흐름도와 정상 질의 sequence를 draw.io 원본 + SVG
  표시로 전환.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 README 목표 구조 화살표/라벨 정리

- `docs/readme-target-structure.drawio`의 반환 화살표 경로를 분리해 입력/마스킹 화살표와 겹치지 않도록 조정.
- draw.io edge label이 흰 배경으로 화살표를 가리지 않도록 라벨을 독립 텍스트 셀로 분리.
- `docs/readme-target-structure.svg`도 같은 경로와 라벨 배치로 갱신.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 정상 질의 sequence 화살표/라벨 정리

- `docs/architecture-normal-sequence.drawio`의 메시지 라벨을 화면 기준으로 모두 화살표 위쪽에 배치.
- 왼쪽/오른쪽 방향 화살표의 draw.io offset 차이를 보정해 텍스트가 화살표를 가리지 않도록 조정.
- `docs/architecture-normal-sequence.svg`를 갱신.
- `./init.sh` 통과로 문서 변경 후 baseline 유지 확인.

## 2026-07-03 MCP stdio 서버 최소 구현

- `docs/mcp-tool-contract.md`에 MCP tool 이름, 입출력, 권한 경계를 정리.
- `fhe-privacy mcp serve --role agent|gateway|local-egress` CLI와 `fhe.mcp.server` stdio
  JSON-RPC 서버를 추가.
- `agent-safe`, `gateway-internal`, `local-egress` role 기반 tool 권한 분리 구현.
- `tests/test_mcp_server.py`에 initialize/tools list round-trip, 권한 거부, PII mask, FHE op
  검증을 추가.
- `./init.sh` 통과로 ruff, format, mypy, pytest 107개 확인.

## 2026-07-03 Secure Gateway 최소 pipeline 구현

- `fhe/gateway/runtime.py`에 `SecureGateway`를 추가.
- ingress는 MCP `gateway` role의 `pii.mask_text` 경로로 사용자 입력을 Agent/LLM 전에 마스킹.
- egress는 MCP `local-egress` role의 `pii.resolve_markers` 경로로 최종 응답을 로컬에서 해결.
- `tests/test_gateway.py`에 LLM-facing payload 평문 누출 방지, reveal marker 로컬 해결,
  unknown marker fail-closed 회귀 테스트 추가.
- `./init.sh` 통과로 ruff, format, mypy, pytest 110개 확인.

## 2026-07-03 범용 Agent adapter 계약 정리

- `docs/agent-adapter-contract.md` 추가.
- OpenClaw/Hermes를 핵심 런타임에 하드코딩하지 않고 reference adapter로 다루는 방향으로 정리.
- Agent capability model, `tool-only`/`secure-gateway` 모드 조건, adapter doctor 출력 계약,
  adapter profile 기반 설치 흐름을 정의.

## 2026-07-03 범용 Agent adapter 코드화

- `fhe/adapter/profiles.py` 추가.
- adapter capability model, `tool-only`/`secure-gateway` mode 판정, doctor 결과, install plan 생성
  로직 구현.
- `fhe-privacy adapter list`, `adapter doctor`, `adapter install` plan CLI 추가.
- `tests/test_adapter_profiles.py`로 tool-only 경고와 secure-gateway fail-closed 동작 검증.

## 2026-07-03 Agent adapter safe config writer

- `fhe/adapter/installer.py` 추가.
- `adapter install`을 기본 dry-run으로 유지하고 `--apply`일 때만 JSON 설정 파일을 쓰도록 변경.
- 기존 Agent 설정 파일이 있으면 쓰기 전에 `.bak`, `.bak.1` 형태로 백업.
- MCP stdio 등록과 secure-gateway metadata를 기존 JSON 설정에 병합.

## 2026-07-03 OpenClaw/Hermes reference adapter profile

- `openclaw`, `hermes` builtin adapter profile 추가.
- 두 profile 모두 현재는 MCP server 등록만 검증된 `tool-only`로 둠.
- OpenClaw는 JSON `mcp.servers`, Hermes는 YAML `mcp_servers` 경로로 MCP server 설정을 렌더링.
- pre-LLM/post-LLM wrapper 지점이 확인되기 전까지 LLM 평문 0을 주장하지 않음.

## 2026-07-03 Reference adapter smoke test

- OpenClaw/Hermes `adapter doctor` CLI가 `tool-only`와 `llm_plaintext_zero_claim: no`를 출력하는지 검증.
- OpenClaw `adapter install --apply`가 JSON `mcp.servers.fhe-privacy`를 병합하고 `.bak` 백업을 생성하는지 검증.
- Hermes `adapter install --apply`가 빈 YAML target에 `mcp_servers.fhe-privacy`를 생성하는지 검증.

## 2026-07-03 Secure gateway wrapper 조사

- `docs/secure-gateway-wrapper-investigation.md`에 OpenClaw/Hermes의 MCP 연결점, plugin/hook 후보,
  secure-gateway 승격 조건을 정리.
- 두 reference profile은 MCP 등록만 검증된 `tool-only`로 유지.
- `adapter doctor --mode secure-gateway`가 wrapper, pre-LLM 입력 경계, post-LLM egress 경계
  미검증 blocker를 출력하도록 추가.

## 2026-07-06 아키텍처 다이어그램 정리 (프라이버시 게이트웨이)

- `docs/architecture-component-flow.drawio`를 개념 설명용으로 대폭 개선:
  - MCP Server를 허브로 두고 Gateway·Agent가 role 단위로 호출하는 구조를 명시(MCP 경유 명시).
  - 세 흐름을 색으로 분리: ① 프롬프트→LLM(마스킹, 파랑) ② Tool Calling·동형 연산(주황) ③ 결과 복호·출력(초록).
  - 런타임 구성요소(PII·FHE Client·FHE Ops·Local Vault)를 에메랄드로 통일하고 `MCP tool runtime` 영역으로 묶음. Secure Gateway·MCP Server는 런타임 밖(호출자 / access layer).
  - `Vault → FHE Ops (ciphertext inputs)`, `FHE Client → MCP (decrypt → plaintext)` 화살표 추가로 데이터 경로 완결.
  - 코드 식별자 라벨(`fhe.op_*` 등)을 개념어(encrypted computation 등)로 교체.
- `docs/rag-fhe-flow.drawio`(신규, 암호문 RAG 검색 파이프라인)와 `docs/architecture-rag-combined.drawio`(신규, 두 다이어그램 무손실 병합) 추가.
  - 병합 seam: `Selected Chunks → Prompt Builder → Secure Gateway(mask) → Agent → LLM`.
  - 정합성 수정: Decrypt+Rank를 로컬(sk) 영역으로, RAG 출력은 Gateway 마스킹 경유. 외부 LLM 1개로 통합.
- **주의:** `architecture-component-flow.svg`는 최신 drawio와 어긋남(구 레이아웃). diagrams.net에서 재export 필요.

## 2026-07-06 용어 정리

- 시스템 대표 명칭 = **프라이버시 게이트웨이**(별도 로컬 보안 서비스). 산출물 = **패키지/툴킷**. **런타임**은 내부 실행 객체 `MCPToolRuntime`에만 사용.
- `docs/fhe-features.md`에 용어(Terminology) 정의 블록 추가, RTE-01 `로컬 런타임 패키지`→`로컬 패키지`, 섹션 `런타임 코어`→`패키지 · 하네스`.
- `AGENTS.md`·`README.md`·`feature_list.json`의 제품 설명 `런타임`→`시스템(패키지로 배포)`.
- 설계 논의: 권장 타깃 = pre-LLM 강제 마스킹 어댑터(프록시) + 비밀키 단독 소유 로컬 런타임 데몬. tool-only는 '프라이버시 모드' 포장에서 격하 예정(코드 제거는 secure-gateway 러너 확보 이후).

## 2026-07-08 Reveal 장치 / 신뢰 경계 설계 노트

- `docs/reveal-device-policy.md` 추가.
- 로컬 전체를 신뢰영역으로 두기보다 `reveal authority` / `decrypt authority`를 최소화하는 방향으로 정리.
- TPM-backed Local Reveal을 기본 권장 모드로 정의하고, FHE secret key는 TPM/Intel PTT wrapping key로 저장 중 보호하는 방향으로 정리.
- 스마트폰은 기본 메시징 채널이나 기본 reveal 장치가 아니라 고위험 reveal의 step-up 장치로 재정의.
- 기본 모드(TPM-backed Local Reveal), 선택적 강화 모드(Smartphone Step-up Reveal), 고보증 모드(High-Assurance Reveal)를 구분.
- 생체인증은 기본 UX가 아니라 step-up reveal의 세션 승인, batch approval, 고위험 매건 인증 조합으로 정리.
- risk-based reveal policy와 향후 `RevealRequest` / `RevealPolicy` / `RevealAuthority` 추상화 방향을 기록.
- TPM-backed local reveal과 스마트폰 step-up 구조를 하나의 end-to-end 흐름으로 통합.
- `docs/reveal-device-flow.drawio` / `.svg`를 TPM-backed local reveal + smartphone step-up 구조로 갱신.
- 커밋 기록:
  - `2cc9f07 docs: add reveal device policy`
  - `1101f7f docs: merge reveal device flow`
  - `95187b4 docs: add reveal device flow diagram`
  - `0c79a59 docs: make TPM-backed reveal the default`
- 세션 종료 시점에 reveal policy 관련 변경은 모두 커밋 완료. 별도 다이어그램 rename/delete로 보이는 작업트리 변경은 기존 작업으로 남겨둠.

## 2026-07-09 Threshold FHE Reveal 설계 노트

- `docs/threshold-fhe-reveal.md` 추가.
- `docs/reveal-device-policy.md`를 Threshold FHE 중심 정책으로 재정리.
- `docs/reveal-device-policy.md`의 신뢰/비신뢰 경계를 추상 개념 대신 `SecureGateway`,
  local-egress, reveal policy, threshold authorities, PC/phone OS, external Agent/LLM 등
  구체 구성요소별 표로 명시.
- `docs/reveal-device-flow.drawio` / `.svg`를 Local Convenience Reveal, Smartphone Step-up Approval,
  Threshold PC Fusion, Threshold Phone Fusion + Display Only 라우팅 구조로 갱신.
- Multiparty FHE와 Threshold FHE의 용어 범위를 구분하고, 설계 용어는 `Threshold FHE Reveal`,
  구현/API 용어는 OpenFHE `Multiparty*` 계열로 분리.
- PC와 스마트폰의 `2-of-2` secret share, `pk_joint`, `eval_keys_joint`, partial decrypt,
  fusion 위치(PC vs phone)별 보안 성질을 정리.
- 고보증 reveal의 권장 경로를 `phone fusion + phone display only`로 정의.
- TPM/Intel PTT/TEE는 threshold FHE의 필수 전제가 아니라 local reveal 또는 secret share
  저장 보호를 위한 optional hardening으로 정리.
- OpenFHE Python 바인딩에서 `MultipartyKeyGen`, `MultipartyDecryptLead/Main/Fusion`,
  `Multi*Eval*` API가 노출되는 것을 확인하고, 후속 구현은 bundle v5/별도 backend spike로
  분리하는 방향을 기록.
- 이후 `docs/reveal-device-policy.md`는 세부 정책/구현 계획을 덜어내고 전체 동작 흐름,
  reveal 모델, threshold FHE 개념, Gateway 경계를 설명하는 개념 설계 문서로 축약.
- `docs/reveal-device-policy.md`에서 `핵심 결론`, `문서화해야 할 보안 주장`, `구현 방향`
  섹션 제거.
- 문장 표현을 서술형에서 개조식 명사구 중심으로 정리하고, 코드블록 없이 표와 bullet만 사용.
- `docs/reveal-device-flow.drawio`의 겹치던 화살표를 정리.
  - `Phone Fusion -> PC output` status 반환선 제거.
  - `PC/phone partial -> PC Fusion` 긴 역방향 dashed 선 제거.
  - `Reveal Policy -> PC Fusion -> PC output` 개념 분기로 단순화.
  - `docs/reveal-device-flow.svg` 재생성.

## 검증

- `./init.sh` 통과 (2026-07-03): ruff, ruff format, mypy, pytest 129개.
- 2026-07-06: 문서/다이어그램(.drawio/.md/.json)만 변경, 코드 무변경 — `./init.sh` 재실행 안 함.
- 2026-07-08: `./init.sh` 통과 (ruff, ruff format, mypy, pytest 129개).
- 2026-07-09: `./init.sh` 통과 (ruff, ruff format, mypy, pytest 129개).
