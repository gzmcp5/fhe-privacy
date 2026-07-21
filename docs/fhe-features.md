# FHE-Privacy — 재설계 기능 목록

> 현재 제품 코드는 삭제된 상태다. 이 문서는 RAG 없는 신규 아키텍처의 목표 기능을 정의하며,
> 검증 전에는 어떤 항목도 `passing`으로 표시하지 않는다.

보안 결정 기준: [`1-0. security-architecture-index.md`](1-0.%20security-architecture-index.md)

## 상태

- `not_started`: 구현과 검증 근거 없음
- `active`: WIP 1개만 허용
- `blocked`: 외부 결정이나 선행 조건 때문에 진행 불가
- `passing`: 명시된 검증이 통과한 경우만 사용

## 1. 아키텍처 경계

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| ARC-01 | 비신뢰 Agent/LLM 위협 모델 | not_started | threat model review와 negative test 목록 확정 |
| ARC-02 | Gateway-only raw ingress | not_started | canary 부재와 connect/exec/direct-input 우회 거부 |
| ARC-03 | OpenShell sealed Agent 격리 | not_started | key/Vault 차단과 connect/sync/forward 거부 테스트 |
| ARC-04 | 비신뢰 Stateless Agent MCP Bridge | not_started | capability 복제 무권한 상승과 restart 테스트 |
| ARC-05 | Session-scoped Privacy Core | not_started | session 생성/종료/격리 테스트 |
| ARC-06 | Authority channel 분리 | not_started | Agent가 host-only/reveal channel에 접근하지 못함 |

## 2. PII와 입력 정책

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| PII-01 | UTF-8 텍스트 ingress | not_started | 크기/encoding/정규화 테스트 |
| PII-02 | 지원 PII detector | not_started | kind별 positive/negative/Unicode 회귀 테스트 |
| PII-03 | Ambiguity fail-closed | not_started | 불확실 입력에서 Agent 호출 0회 |
| PII-04 | Masked envelope | not_started | 구조화된 segment와 marker 무결성 테스트 |
| PII-05 | 비지원 content 거부 | not_started | attachment/memory/tool plaintext 거부 테스트 |
| PII-06 | 풍부한 PII catalog | not_started | kind별 형식/checksum/context와 이름 제외 테스트 |

## 2-1. 파일 ingress

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| FIL-01 | File Phase 1 format | not_started | TXT/Markdown/CSV/TSV/JSON positive·malformed·quota tests |
| FIL-02 | Canonical Document IR | not_started | block/cell/location/coverage와 masked projection 무결성 테스트 |
| FIL-03 | Encrypted original object store | not_started | chunk AEAD/manifest/2-of-2 DEK envelope/atomic commit/cleanup 테스트 |
| FIL-04 | Isolated parser boundary | not_started | network/workspace/other-object/key 접근과 crash/timeout 거부 테스트 |
| FIL-05 | DOCX profile | not_started | 모든 text-bearing part coverage와 macro/OLE/external 관계 거부 |
| FIL-06 | Born-digital PDF profile | not_started | page coverage와 encrypted/active/embedded/OCR-required 거부 |
| FIL-07 | Direct-file bypass 차단 | not_started | workspace/MCP/provider attachment 경로에서 Agent 원문 접근 거부 |
| FIL-08 | Output Document IR | not_started | schema/policy/provenance/marker/destination binding 검증 |
| FIL-09 | Isolated Document Renderer | not_started | 2-of-2 file Fusion Sink, format 재파싱, path/injection/partial-write 거부 |

## 3. Vault와 handle

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| VLT-01 | Opaque typed handle | not_started | 예측 불가 ID와 type 검증 |
| VLT-02 | Session binding | not_started | cross-session/replay 거부 테스트 |
| VLT-03 | Context/provenance binding | not_started | key/context/type/operation 불일치 거부 |
| VLT-04 | Atomic result registration | not_started | 저장 실패 시 result handle 미발급 |
| VLT-05 | Session cleanup | not_started | 종료 후 handle/capability 무효화 |
| VLT-06 | Vault storage format | not_started | v1 in-memory cleanup; 후속 SQLite metadata + binary BLOB transaction 검증 |

## 4. 암호 계층

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| CRY-01 | 2-of-2 multiparty key material | not_started | 완성 key 부재와 PC/phone 한쪽 reveal 거부 |
| CRY-02 | CKKS approximate numeric | not_started | domain별 precision/error와 2-of-2 fusion 통과 |
| CRY-03 | BFV/BGV exact integer | not_started | modulus/overflow/encoding과 2-of-2 fusion 검증 |
| CRY-04 | Boolean FHE exact predicate | not_started | equality/predicate와 mobile multiparty 지원 검증 |
| CRY-05 | Exact threshold-envelope Vault | not_started | record DEK, 2-of-2 unwrap, tamper와 phone fusion 검증 |
| CRY-06 | Malformed ciphertext 거부 | not_started | serialization/scheme/shape/context negative test |
| CRY-07 | Subprocess backend | not_started | bytes/handle API와 crash isolation 테스트 |

## 5. MCP Bridge와 Core protocol

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| MCP-01 | Agent MCP stdio Bridge | not_started | initialize/list/call round-trip |
| MCP-02 | Handle-only FHE tools | not_started | raw plaintext/ciphertext 인자 거부 |
| MCP-03 | HTTPS/mTLS Agent-safe Core interface | not_started | sandbox/session/lease/policy/operation 검증 |
| MCP-04 | Host-only Core interface | not_started | Agent sandbox 접근 거부 |
| MCP-05 | Resource limits | not_started | timeout/quota/oversize request 거부 |

## 6. Reveal과 egress

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| REV-01 | Gateway terminal egress | not_started | plaintext가 Agent/history로 돌아가지 않음 |
| REV-02 | Reveal Policy | not_started | input secret/unknown/provenance 없는 handle 거부 |
| REV-03 | PC/phone partial authority 분리 | not_started | share 격리와 한쪽 단독 reveal 거부 |
| REV-04 | Streaming marker buffering | not_started | 불완전 marker와 조기 plaintext 출력 방지 |
| REV-05 | PC/Phone Fusion Sink | not_started | destination-bound 2-of-2 fusion과 plaintext 위치 검증 |
| REV-06 | 2-of-3 recovery | not_started | single-key backup 없이 device-loss 복구 검증 |

## 7. Adapter와 배포

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| ADP-01 | 범용 capability contract | not_started | ingress/egress/sealed sandbox/agent-safe HTTPS 판정 |
| ADP-02 | Adapter doctor | not_started | 미충족 조건을 fail-closed blocker로 출력 |
| ADP-03 | Hermes reference adapter | not_started | raw-input bypass와 direct-output 경로가 없음 |
| DST-01 | OpenShell sealed policy profile | not_started | hard isolation/network/management API/lease 검증 |
| DST-02 | Source/package install | not_started | clean environment install과 checksums |
| DST-03 | Windows/portable backend | not_started | named pipe/engine bundle security test |

## 명시적 초기 비범위

- RAG/vector DB/embedding
- 웹앱, 채팅 UI, 자체 LLM loop
- 허용 목록 밖의 attachment, OCR, 이미지 분석, 음성
- 다중 사용자 SaaS
- 네트워크 공개 MCP endpoint
- OS/kernel 완전 침해 방어
