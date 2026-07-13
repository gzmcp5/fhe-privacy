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
| P4 | 암호 저장 분리 | CKKS numeric + exact secret AEAD | precision/tamper/context tests |
| P5 | Public FHE Worker | public bundle과 handle operation | secret-free process/operation budget tests |
| P6 | MCP stdio Bridge | stateless handle-only tool server | round-trip/tool absence/Core failure tests |
| P7 | Authority channels | host-only/agent-safe/reveal interface | privilege escalation negative tests |
| P8 | Gateway ingress/egress | masked envelope + terminal reveal | raw-input/output bypass tests |
| P9 | OpenShell adapter | full-process sandbox와 Core relay | filesystem/network/canary E2E tests |
| P10 | Reveal hardening | risk policy, step-up/threshold extension | oracle/replay/destination tests |
| P11 | Packaging/operations | clean install, checksums, doctor, migration | clean-machine/security checklist |

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
- AEAD: 이름, 전화, 주소, credential 등 exact secret
- exact integer/회계 금액: 별도 결정 전 지원 보류

### MCP는 마지막 adapter

Core domain API를 먼저 검증하고 MCP Bridge는 그 제한된 agent-safe interface만 노출한다. Gateway와
Reveal Authority를 MCP tool로 재사용하지 않는다.

## 필수 보안 테스트 범주

- canary 원문이 Agent/LLM/log에 없는지
- unsupported input과 ambiguity에서 Agent 호출 0회
- Agent sandbox의 key/Vault/host-only/reveal channel 접근 거부
- unknown/cross-session/expired/context mismatch handle 거부
- raw plaintext/ciphertext MCP argument 거부
- Core/Bridge crash와 restart fail-closed
- operation quota/depth/timeout/oversize payload
- input secret direct reveal과 Agent-bound plaintext 거부
- terminal sink 이후 plaintext feedback 경로 부재

## 단계별 문서 갱신

각 단계 시작 전에 `feature_list.json`에서 항목 하나만 `active`로 바꾸고, 완료 시 다음을 기록한다.

- 구현 파일
- threat/negative test
- 정확한 verification command
- 결과와 날짜
- 남은 제한과 보안 주장 범위

세부 architecture 결정이 바뀌면 먼저 `docs/1-*.md`와 draw.io를 갱신한 뒤 구현한다.
