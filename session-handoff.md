# 세션 핸드오프

## 현재 목표

RAG 없이 `docs/1. architecture-component-flow.drawio`를 기준으로 FHE-Privacy를 처음부터
재구축한다. 현재는 구현 전 설계 단계다.

## 저장소 상태

- 로컬 경로는 `/home/gildellmint/Workspace/AGENTS/FHE-Privacy`이고 원격은
  `https://github.com/gzmcp5/fhe-privacy.git`이다. `main`은 `origin/main`을 추적한다.
- FHE-Privacy는 2026-07-14 OpenShell fork의 하위 snapshot에서 독립 최상위 제품 저장소로 분리됐다.
  OpenShell은 `versions.lock`로 고정하는 외부 sandbox runtime dependency이며 FHE-Privacy 구현을
  소유하지 않는다.
- 새 저장소는 기존 `fhe-privacy/` 경로의 3개 커밋 이력을 `git subtree split`로 보존했다. 기존
  FHE-Privacy 원격 `main`은 이 이력과 새 제품 구조로 초기화했다.
- `adapters/openshell/`, `images/hermes/`, `deploy/`는 제품 경계를 표시하는 초기 scaffolding이며
  구현 완료 근거가 아니다.
- Agent 지침과 상태 파일은 저장소 루트의 `AGENTS.md`, `CLAUDE.md`, `feature_list.json`,
  `progress.md`, `session-handoff.md`에 둔다. 별도 `harness/` routing directory는 사용하지 않는다.
- 제품 코드(`fhe/`), 테스트(`tests/`), 제품 스크립트(`scripts/`)는 삭제된 상태다.
- OpenShell 공식 `v0.0.80` Linux x86-64 musl 바이너리가 gitignore된
  `artifacts/openshell/0.0.80/bin/openshell`에 설치되어 있고 `artifacts/bin/openshell`이 이를
  가리킨다. `versions.lock`에는 tag commit과 공식 archive checksum이 고정되어 있다. 다른 플랫폼,
  container와 Helm chart 입력은 계속 `UNVALIDATED`다.
- OpenFHE 1.5.1/OpenFHE-Python 1.5.1.0의 Ubuntu 24.04 x86-64 CPython 3.13 wheel이 gitignore된
  `vendor/wheels/`에 설치되어 있다. `tools/openfhe/`에는 pinned source build와 BFV/BGV/CKKS/Boolean,
  2-party fusion smoke test가 있고 `.github/workflows/openfhe-wheels.yml`은 Linux와 macOS arm64 wheel을
  별도 생성한다. Linux wheel은 검증·checksum 고정됐고 macOS wheel은 runner 실행 전 `UNVALIDATED`다.
- 새 clone에서 native runtime이 필요한 에이전트는 `AGENTS.md`에 따라
  `./tools/bootstrap-dev-runtime.sh`를 실행한다. 이 entrypoint는 고정 OpenShell asset을 다운로드·검증하고
  플랫폼별 OpenFHE wheel을 고정 commit에서 빌드·smoke test한다. macOS에서는 실행 준비가 가능하지만
  실제 Mac 테스트 근거 전까지 OpenShell compatibility와 OpenFHE checksum 상태를 validated로 바꾸지 않는다.
- 2026-07-14 macOS arm64 로컬 실행에서 bootstrap이 완료됐다. 생성물은 gitignore된
  `artifacts/openshell/0.0.80/bin/openshell`과
  `vendor/wheels/openfhe-1.5.1.0.14.0-cp313-cp313-macosx_14_0_arm64.whl`이며, OpenFHE wheel SHA-256은
  `1c99f50a6203cb71f9a2f083dde40c7375e9ebac58d36f85ddf46fcf16edfc2c`이다. Smoke test는 BFV/BGV/CKKS,
  Boolean FHE, BGV 2-of-2 partial decrypt/fusion을 통과했다. 이 근거는 native dependency build
  확인이며 제품 기능 `passing` 근거는 아니다.
- 과거 구현 완료 기록은 현재 제품 상태의 근거가 아니다.
- `feature_list.json`과 `docs/fhe-features.md`의 기능은 검증 전까지 `not_started`다.
- `./init.sh`는 구현 재개 후 복구할 완료 게이트이며 현재 설계 검증에는 사용하지 않는다.
- RAG 문서는 이번 정합성 수정 범위에서 제외했다.
- 저장소 구조 전환 기준 커밋은 `6e4f1c6f` (`chore(harness): move agent state files to root`)와
  `c00ad1f6` (`chore(repo): establish FHE-Privacy product repository`)다.
- OpenShell fork `https://github.com/gzmcp5/OpenShell.git`의 `main`은 FHE-Privacy snapshot을 복사하기
  직전 커밋 `94cdd697`로 force-with-lease 복구했다. OpenShell 저장소에는 FHE-Privacy 제품 파일이 없다.
- `mise` 2026.7.5를 사용자 계정에 설치하고 zsh activation과 이 저장소 trust를 설정했다.
- `mise install`은 사용자 요청으로 중단했다. 이후 상태 기록 전 `mise run pre-commit`이 누락 도구를
  자동 설치하면서 Rust 1.95.0과 Skaffold 2.20.0 설치가 완료됐다. Zig 0.14.1만 `missing` 상태이며
  자동 설치는 다시 중단했다. Pre-commit 본 작업은 실행 완료되지 않았다.

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
16. FHE-Privacy가 최상위 제품과 사용자 진입점이다. 제품 관계는
    `사용자 -> FHE-Privacy -> OpenShell -> Hermes`다.
17. Secure Gateway는 OpenShell을 제품/워크플로 수준에서 감싸고 오케스트레이션하지만 OpenShell
    Gateway와 같은 프로세스나 권한 영역으로 합치지 않는다.
18. 로컬 배포에서 FHE-Privacy installer는 검증된 고정 버전의 OpenShell host package/binary를
    설치한다. Kubernetes에서는 별도 OpenShell Gateway/Supervisor image와 Helm chart를 배포한다.
19. Hermes는 OpenShell이 실행하는 OCI workload image다. Secure Gateway, Privacy Core, OpenShell
    Gateway와 Hermes sandbox를 하나의 container image에 합치지 않는다.
20. FHE-Privacy secure session의 사용자 진입점은 `fhe-privacy` CLI다. OpenShell CLI 전체를
    복제하지 않지만 sealed sandbox에 대한 direct connect/exec/sync/forward는 차단한다.
21. OpenShell 수정이 필요하면 sealed management access, workload identity, policy revision/lease
    binding 같은 범용 기능만 OpenShell fork/upstream에 구현한다. PII, Vault, FHE와 reveal 코드는
    FHE-Privacy에 둔다.
22. 수정된 OpenShell이 upstream release에 없다면 FHE-Privacy release CI가 고정 commit에서 미리
    빌드하고 checksum/digest를 기록한다. 최종 사용자는 OpenShell 소스를 빌드하지 않는다.

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

1. 새 세션 시작 시 `AGENTS.md`, 이 파일, `feature_list.json`, `progress.md`,
   `docs/1-0. security-architecture-index.md`, `docs/architecture-flow.md`를 순서대로 읽는다.
2. `git status --short --branch`로 `main...origin/main` clean 상태를 확인한다.
3. `docs/fhe-development-plan.md`의 P0부터 새 Python package/test/CLI skeleton과 `init.sh` 검증
   entrypoint를 복구한다. 첫 active feature는 하나만 선택한다.
4. 개발 도구가 필요하면 `mise install zig@0.14.1`로 중단된 설치만 재개하고 `mise doctor`를 실행한다.
5. 실제 구현 전 agent-safe HTTPS/mTLS, sealed full-process containment와 deny-by-default network
   policy를 작은 spike로 검증한다.
6. Host-only/reveal UDS의 OS identity, permission과 capability lease 전달 방식을 검증한다.
7. 각 단계는 허용 경로 테스트뿐 아니라 우회·재생·교차 세션·권한 상승 거부 테스트를 포함한다.

## 남는 위험과 보안 주장 한계

- PII detector 누락, sandbox/host 침해, supply-chain, endpoint 화면·클립보드 탈취,
  metadata/timing leakage, CKKS 근사 오차와 구현 버그는 별도 위험으로 남는다.
- 따라서 목표 주장은 “지원 입력과 검증된 경로에서 비신뢰 Agent/LLM에 민감 plaintext와 secret
  key를 제공하지 않는다”로 제한한다. 시스템 전체의 절대적 기밀성을 주장하지 않는다.
