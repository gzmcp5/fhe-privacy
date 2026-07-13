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
| ARC-02 | Gateway-only raw ingress | not_started | canary 원문이 Agent/LLM/log에 없음을 검증 |
| ARC-03 | OpenShell 전체 Agent 격리 | not_started | key/Vault/host-only channel 접근 거부 테스트 |
| ARC-04 | Stateless Agent MCP Bridge | not_started | Bridge restart와 Core session 연속성 테스트 |
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

## 3. Vault와 handle

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| VLT-01 | Opaque typed handle | not_started | 예측 불가 ID와 type 검증 |
| VLT-02 | Session binding | not_started | cross-session/replay 거부 테스트 |
| VLT-03 | Context/provenance binding | not_started | key/context/type/operation 불일치 거부 |
| VLT-04 | Atomic result registration | not_started | 저장 실패 시 result handle 미발급 |
| VLT-05 | Session cleanup | not_started | 종료 후 handle/capability 무효화 |

## 4. 암호 계층

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| CRY-01 | CKKS public/secret material 분리 | not_started | Public Worker bundle에 secret 없음 |
| CRY-02 | CKKS numeric round-trip | not_started | domain별 precision/error 기준 통과 |
| CRY-03 | Public homomorphic operations | not_started | add/sub/scale/mul depth와 context 검증 |
| CRY-04 | Exact secret AEAD Vault | not_started | 이름/전화/credential exact 복원과 tamper 거부 |
| CRY-05 | Malformed ciphertext 거부 | not_started | serialization/shape/context negative test |
| CRY-06 | Subprocess backend | not_started | bytes/handle API와 crash isolation 테스트 |

## 5. MCP Bridge와 Core protocol

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| MCP-01 | Agent MCP stdio Bridge | not_started | initialize/list/call round-trip |
| MCP-02 | Handle-only FHE tools | not_started | raw plaintext/ciphertext 인자 거부 |
| MCP-03 | Agent-safe Core interface | not_started | session capability와 operation allowlist 검증 |
| MCP-04 | Host-only Core interface | not_started | Agent sandbox 접근 거부 |
| MCP-05 | Resource limits | not_started | timeout/quota/oversize request 거부 |

## 6. Reveal과 egress

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| REV-01 | Gateway terminal egress | not_started | plaintext가 Agent/history로 돌아가지 않음 |
| REV-02 | Reveal Policy | not_started | input secret/unknown/provenance 없는 handle 거부 |
| REV-03 | Reveal Authority 분리 | not_started | Agent/Public Worker에 secret key 없음 |
| REV-04 | Streaming marker buffering | not_started | 불완전 marker와 조기 plaintext 출력 방지 |
| REV-05 | Step-up/threshold extension | not_started | 별도 장치와 partial decrypt 검증 후 도입 |

## 7. Adapter와 배포

| ID | 기능 | 상태 | 완료 조건 |
|---|---|---|---|
| ADP-01 | 범용 capability contract | not_started | ingress/egress/OpenShell/Core relay capability 판정 |
| ADP-02 | Adapter doctor | not_started | 미충족 조건을 fail-closed blocker로 출력 |
| ADP-03 | Hermes reference adapter | not_started | raw-input bypass와 direct-output 경로가 없음 |
| DST-01 | OpenShell policy profile | not_started | hard isolation/network/filesystem 검증 |
| DST-02 | Source/package install | not_started | clean environment install과 checksums |
| DST-03 | Windows/portable backend | not_started | named pipe/engine bundle security test |

## 명시적 초기 비범위

- RAG/vector DB/embedding
- 웹앱, 채팅 UI, 자체 LLM loop
- attachment, OCR, 음성
- 다중 사용자 SaaS
- 네트워크 공개 MCP endpoint
- OS/kernel 완전 침해 방어
