# 세션 핸드오프

## 현재 목표

RAG 없이 `docs/1. architecture-component-flow.drawio`를 기준으로 FHE-Privacy를 처음부터
재구축한다. 현재는 구현 전 설계 단계다.

## 저장소 상태

- 제품 코드(`fhe/`), 테스트(`tests/`), 제품 스크립트(`scripts/`)는 삭제된 상태다.
- 과거 구현 완료 기록은 현재 제품 상태의 근거가 아니다.
- `feature_list.json`과 `docs/fhe-features.md`의 기능은 검증 전까지 `not_started`다.
- `./init.sh`는 구현 재개 후 복구할 완료 게이트이며 현재 설계 검증에는 사용하지 않는다.
- RAG 문서는 이번 정합성 수정 범위에서 제외했다.

## 확정한 기본 설계

1. 외부 Agent 구현체는 Hermes로 확정한다. Hermes와 LLM은 비신뢰이며 Hermes 전체를 OpenShell
   sandbox 안에서 실행한다. 지원 완료 표시는 adapter E2E 검증 후에만 한다.
2. Secure Gateway는 원문의 유일한 진입점이다. 검출·암호화·Vault 저장·검증에 실패하거나
   불확실하면 Agent를 호출하지 않는다.
3. OpenShell 내부 Agent MCP Bridge는 stateless이며 secret key, Vault, plaintext와 reveal 코드를
   갖지 않는다. Bridge와 Hermes는 하나의 비신뢰 sandbox principal이며 Bridge capability의 기밀성은
   보안 경계가 아니다.
4. Agent는 opaque, typed, session-bound handle로 허용된 공개 연산만 요청한다.
5. Gateway host-only, Agent-safe, Reveal Coordinator와 PC/phone partial decrypt 채널을 물리적으로
   분리한다. 요청의 `role`
   문자열은 보안 경계가 아니다.
6. Public Compute Worker는 secret-free/confidentiality-untrusted 영역이다. 결과 무결성과 provenance는
   Core가 별도로 검증한다.
7. FHE secret은 PC의 `sk_pc`와 스마트폰의 `sk_phone` share로만 보관한다. 기본 2-of-2 reveal은
   두 장치가 모두 승인·참여해야 하며 완성된 secret key를 생성하거나 single-key로 fallback하지 않는다.
8. CKKS는 허용 오차가 명시된 수치 데이터에만 사용한다. BFV/BGV는 exact integer, Boolean FHE는
   exact predicate에 사용한다. 주민등록번호처럼 계산하지 않는 exact identifier는 record별 AEAD와
   2-of-2 threshold envelope로 보호한다.
9. 초기 범위는 trusted text ingress만 지원한다. attachment, OCR, audio, clipboard 자동수집,
   memory import, tool output의 plaintext 유입은 명시적으로 차단한다.
10. OpenShell은 프로세스·filesystem·network 격리 계층이며 위 데이터 흐름 통제를 대체하지 않는다.
11. Agent-safe Core는 sandbox 전체가 호출할 수 있는 HTTPS/mTLS endpoint로 제공한다. Host-only Core,
    Reveal Coordinator와 PC partial authority는 서로 다른 local UDS에만 bind하며 기존 OpenShell
    relay는 재사용하지 않는다. Phone authority는 장치 인증된 별도 채널만 사용한다.
12. Secure mode는 connect/SSH, exec, sync, forward와 직접 Agent 입력을 차단한 sealed sandbox만
    사용한다. Core capability는 sandbox/session/policy revision과 짧은 lease에 바인딩한다.
13. Exact secret은 record별 임의 DEK로 AEAD 암호화하고 DEK를 PC·스마트폰 2-of-2 envelope로 감싼다.
    장기 AEAD master key는 두지 않는다. Public Compute Worker는 초기 버전에서 결과 무결성 측면의
    신뢰된 로컬 프로세스다.
14. 이름은 이 제품의 PII 탐지·masking 대상에서 제외한다. 상세 탐지 종류와 예외는
    `docs/pii-detection-catalog.md`를 기준으로 한다.
15. 초기 Vault는 메모리 기반이다. 영속화 단계에서는 SQLite metadata와 binary BLOB을 기본안으로
    검증하며 JSON을 Vault 본체로 사용하지 않는다.

## 기준 문서

- 보안 결정 색인: `docs/1-0. security-architecture-index.md`
- 세부 결정: `docs/1-1. pre-llm-ingress.md`부터 `docs/1-8. operational-security-baseline.md`
- 컴포넌트 흐름: `docs/1. architecture-component-flow.drawio`
- 전체 흐름: `docs/architecture-flow.md`
- 기능 목록: `docs/fhe-features.md`
- 용어 설명: `docs/glossary.md`
- PII 탐지 목록: `docs/pii-detection-catalog.md`
- 개발 계획: `docs/fhe-development-plan.md`
- MCP/Adapter 계약: `docs/mcp-tool-contract.md`, `docs/agent-adapter-contract.md`
- Reveal 정책: `docs/reveal-device-policy.md`, `docs/threshold-fhe-reveal.md`

## 다음 시작점

1. `docs/fhe-development-plan.md`의 P0부터 새 패키지와 검증 하네스를 만든다.
2. 실제 구현 전 agent-safe HTTPS/mTLS, sealed full-process containment와 deny-by-default network
   policy를 작은 spike로 검증한다.
3. Host-only/reveal UDS의 OS identity, permission과 capability lease 전달 방식을 검증한다.
4. 각 단계는 허용 경로 테스트뿐 아니라 우회·재생·교차 세션·권한 상승 거부 테스트를 포함한다.

## 남는 위험과 보안 주장 한계

- PII detector 누락, sandbox/host 침해, supply-chain, endpoint 화면·클립보드 탈취,
  metadata/timing leakage, CKKS 근사 오차와 구현 버그는 별도 위험으로 남는다.
- 따라서 목표 주장은 “지원 입력과 검증된 경로에서 비신뢰 Agent/LLM에 민감 plaintext와 secret
  key를 제공하지 않는다”로 제한한다. 시스템 전체의 절대적 기밀성을 주장하지 않는다.
