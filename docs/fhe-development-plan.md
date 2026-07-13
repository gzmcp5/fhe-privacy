# FHE-Privacy — 재개발 계획

> 제품 코드와 테스트가 없는 상태에서 시작한다. 과거 구현 완료 기록은 현재 계획의 근거가 아니다.
> WIP는 한 번에 하나만 두며 각 단계는 검증 통과 후에만 완료한다.

보안 기준: [`1-0. security-architecture-index.md`](1-0.%20security-architecture-index.md)

## 개발 원칙

- RAG, 자체 LLM loop, 웹 UI와 provider 구현을 추가하지 않는다.
- 먼저 보안 경계와 protocol을 검증하고 OpenFHE 기능을 그 위에 연결한다.
- Agent-facing 프로세스에는 secret key와 reveal 코드를 두지 않는다.
- 모든 외부 입력, handle, ciphertext와 policy metadata를 비신뢰로 다룬다.
- 실패 경로와 권한 거부 테스트를 positive test보다 먼저 정의한다.
- 구현 단계에서 `./init.sh`를 전체 완료 게이트로 복구한다.

## 단계 계획

| 단계 | 목표 | 주요 산출물 | 완료 검증 |
|---|---|---|---|
| P0 | 패키지/테스트 하네스 복구 | 최소 `fhe/`, tests, CLI skeleton | lint/type/test baseline |
| P1 | Domain 계약 | error, session, handle, envelope type | serialization/negative tests |
| P2 | Session Core/Vault | session registry, opaque handle, in-memory Vault | cross-session/replay/cleanup tests |
| P3 | PII ingress | text normalization, detector, fail-closed masking | canary/ambiguity/unsupported input tests |
| P4 | 암호 저장 분리 | CKKS, BFV/BGV, Boolean FHE 계약 + exact threshold envelope | precision/exact/overflow/tamper tests |
| P5 | 2-of-2 key plane | PC/phone joint keygen, partial decrypt/unwrap, fusion | one-share denial/key-set/replay tests |
| P6 | Public FHE Worker | scheme별 joint public bundle과 operation; v1 integrity-trusted | secret-free process/operation budget tests |
| P7 | MCP stdio Bridge | 비신뢰 stateless handle-only adapter | round-trip/tool absence/capability-copy tests |
| P8 | Authority channels | Core/coordinator/PC partial UDS + phone channel + agent-safe HTTPS | privilege escalation/endpoint tests |
| P9 | Gateway ingress/egress | masked envelope + PC/phone Fusion Sink | raw-input/output bypass tests |
| P10 | OpenShell adapter | full-process sealed sandbox와 Core lease | management bypass/network/canary E2E tests |
| P11 | Recovery/operations | 2-of-3 recovery, rotation, clean install, checksums | device-loss/migration/security checklist |

## P0 완료 전 금지

- 과거 feature를 `passing`으로 복원
- 빈 테스트로 `./init.sh` 성공 처리
- secret key를 Agent MCP 프로세스에 임시 로드
- raw ciphertext/Base64를 Agent API의 기본 계약으로 사용
- `role` argument만으로 decrypt/reveal 권한 구분

## 핵심 구현 순서

### Session과 handle 우선

OpenFHE보다 먼저 session/handle/Vault behavior를 fake ciphertext로 검증한다. 이렇게 하면
cross-session, replay, transaction과 failure semantics를 빠르게 확정할 수 있다.

### PII와 암호 방식 분리

- CKKS: 명시적 오차를 허용하는 numeric domain
- BFV/BGV: modulus와 overflow 범위가 정의된 exact integer
- Boolean FHE: equality와 exact predicate; backend 검증 전 미지원
- threshold envelope: 주민등록번호, 전화, 주소, credential 등 계산하지 않는 exact secret
- 이름: 이 프로젝트의 PII detector와 masking 대상에서 제외

주민등록번호는 trusted ingress에서 형식/checksum을 검증한 뒤 exact envelope에 저장한다. 생년월일처럼
필요한 파생 속성은 원본과 분리한다. 명시적 operation contract 없이 identifier를 FHE 산술 입력으로
자동 변환하지 않는다.

### 2-of-2를 먼저 검증

CKKS, BFV/BGV, Boolean FHE 후보는 scheme마다 joint keygen, evaluation key, PC/phone partial decrypt와
fusion을 독립 검증한다. Exact secret의 DEK도 2-of-2 threshold envelope로 보호한다. 어느 한 경로가
실패해도 single-key mode로 fallback하지 않는다.

### MCP는 마지막 adapter

Core domain API를 먼저 검증하고 MCP Bridge는 그 제한된 agent-safe interface만 노출한다. Bridge는
Hermes와 같은 비신뢰 principal이며 독자 credential 기밀성에 의존하지 않는다. Gateway, Reveal
Coordinator, partial authority와 Fusion Sink를 MCP tool로 재사용하지 않는다.

### Direct agent-safe transport 우선

초기 Core transport는 OpenShell의 기존 gateway-to-sandbox relay를 재사용하지 않는다. Sandbox에서
host의 전용 HTTPS/mTLS endpoint로 직접 연결하고, host-only/reveal interface는 local UDS에만 bind한다.
Capability는 sandbox 전체가 볼 수 있다고 가정하고 `sandbox_id`, session, operation, expiry와 policy
revision을 Core에서 검증한다.

## 필수 보안 테스트 범주

- canary 원문이 Agent/LLM/log에 없는지
- unsupported input과 ambiguity에서 Agent 호출 0회
- Agent sandbox의 key/Vault/host-only/reveal channel 접근 거부
- Hermes가 Bridge capability/request를 복제한 뒤 forbidden/cross-session operation 거부
- OpenShell connect/SSH, exec, sync, forward와 Hermes direct input 거부
- unknown/cross-session/expired/context mismatch handle 거부
- raw plaintext/ciphertext MCP argument 거부
- Core/Bridge crash와 restart fail-closed
- supervisor heartbeat 단절, stale policy와 Core lease 만료 fail-closed
- operation quota/depth/timeout/oversize payload
- input secret direct reveal과 Agent-bound plaintext 거부
- terminal sink 이후 plaintext feedback 경로 부재
- PC 또는 phone 한쪽 share만으로 reveal/unwrap 불가
- partial share의 ciphertext hash, session, destination, nonce, expiry와 policy binding
- scheme별 precision, modulus/overflow, predicate와 mobile multiparty compatibility
- 이름이 단독 또는 다른 PII 옆에서 masking되지 않음

## 단계별 문서 갱신

각 단계 시작 전에 `feature_list.json`에서 항목 하나만 `active`로 바꾸고, 완료 시 다음을 기록한다.

- 구현 파일
- threat/negative test
- 정확한 verification command
- 결과와 날짜
- 남은 제한과 보안 주장 범위

세부 architecture 결정이 바뀌면 먼저 `docs/1-*.md`와 draw.io를 갱신한 뒤 구현한다.
