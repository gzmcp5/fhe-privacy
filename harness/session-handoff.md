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
   갖지 않는다.
4. Agent는 opaque, typed, session-bound handle로 허용된 공개 연산만 요청한다.
5. Gateway host-only, Agent-safe, Reveal Authority 채널을 물리적으로 분리한다. 요청의 `role`
   문자열은 보안 경계가 아니다.
6. Public Compute Worker는 secret-free/confidentiality-untrusted 영역이다. 결과 무결성과 provenance는
   Core가 별도로 검증한다.
7. 완성된 secret key는 host-only Reveal Authority만 로드한다. Reveal 결과는 terminal egress로만
   사용자에게 전달하며 Agent, LLM, history 또는 tool 결과로 반환하지 않는다.
8. CKKS는 허용 오차가 명시된 수치 데이터에만 사용한다. 문자열 PII, credential, token 등 정확한
   복원이 필요한 값은 AEAD로 보호한다.
9. 초기 범위는 trusted text ingress만 지원한다. attachment, OCR, audio, clipboard 자동수집,
   memory import, tool output의 plaintext 유입은 명시적으로 차단한다.
10. OpenShell은 프로세스·filesystem·network 격리 계층이며 위 데이터 흐름 통제를 대체하지 않는다.

## 기준 문서

- 보안 결정 색인: `docs/1-0. security-architecture-index.md`
- 세부 결정: `docs/1-1. pre-llm-ingress.md`부터 `docs/1-8. operational-security-baseline.md`
- 컴포넌트 흐름: `docs/1. architecture-component-flow.drawio`
- 전체 흐름: `docs/architecture-flow.md`
- 기능 목록: `docs/fhe-features.md`
- 개발 계획: `docs/fhe-development-plan.md`
- MCP/Adapter 계약: `docs/mcp-tool-contract.md`, `docs/agent-adapter-contract.md`
- Reveal 정책: `docs/reveal-device-policy.md`, `docs/threshold-fhe-reveal.md`

## 다음 시작점

1. `docs/fhe-development-plan.md`의 P0부터 새 패키지와 검증 하네스를 만든다.
2. 실제 구현 전 OpenShell relay/IPC, full-process containment와 deny-by-default network policy를
   작은 spike로 검증한다.
3. Gateway/Core/Worker/Reveal Authority의 OS-level process identity와 capability 전달 방식을 정한다.
4. 각 단계는 허용 경로 테스트뿐 아니라 우회·재생·교차 세션·권한 상승 거부 테스트를 포함한다.

## 남는 위험과 보안 주장 한계

- PII detector 누락, sandbox/host 침해, supply-chain, endpoint 화면·클립보드 탈취,
  metadata/timing leakage, CKKS 근사 오차와 구현 버그는 별도 위험으로 남는다.
- 따라서 목표 주장은 “지원 입력과 검증된 경로에서 비신뢰 Agent/LLM에 민감 plaintext와 secret
  key를 제공하지 않는다”로 제한한다. 시스템 전체의 절대적 기밀성을 주장하지 않는다.
