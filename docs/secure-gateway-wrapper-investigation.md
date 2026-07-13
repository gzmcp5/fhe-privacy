# Secure Gateway Adapter Investigation Checklist

> 구현 대상 Agent는 Hermes로 확정했지만 과거 adapter 구현 코드는 삭제됐다. 현재 Hermes는
> secure-gateway reference adapter로 검증되지 않았다. 이 문서는 Hermes 통합 검증 체크리스트다.

## 승격 조건

Hermes adapter는 다음을 모두 만족해야 한다.

1. Gateway가 사용자 원문의 유일한 ingress를 소유한다.
2. Agent 자체 TUI, webhook, channel과 fallback input을 차단할 수 있다.
3. Agent 전체와 MCP Bridge를 OpenShell sandbox 안에서 실행할 수 있다.
4. key/Vault/host-only/reveal channel을 sandbox에서 차단할 수 있다.
5. masked envelope를 headless 또는 검증된 adapter protocol로 전달할 수 있다.
6. 모든 Agent output과 streaming token을 Gateway egress가 사용자 전에 회수한다.
7. 직접 provider/network 접속을 차단하고 승인된 inference route만 사용한다.
8. handle-only stdio MCP Bridge와 agent-safe Core relay를 사용할 수 있다.
9. canary 누출과 bypass negative test를 자동화할 수 있다.

하나라도 충족하지 못하면 secure-gateway 지원으로 표시하지 않는다.

## 조사 항목

| 영역 | 확인 질문 |
|---|---|
| Ingress | 모든 사용자 입력 source를 Gateway 앞으로 이동할 수 있는가 |
| History | 원문 history/memory가 Agent에 남지 않는가 |
| Attachment | 비지원 content를 확실히 거부할 수 있는가 |
| Process | Agent 본체가 OpenShell supervisor의 restricted child인가 |
| MCP | Bridge 실행 위치와 stdio lifecycle은 무엇인가 |
| Core relay | sandbox에서 agent-safe endpoint만 도달 가능한가 |
| Network | direct provider와 임의 egress가 차단되는가 |
| Output | final/streaming/error output을 모두 Gateway가 회수하는가 |
| Logs | Agent/OpenShell/provider log에 canary가 남지 않는가 |
| Update | Agent version 변경을 감지하고 재검증할 수 있는가 |

## Hermes 상태

Hermes는 확정 구현 대상이지만 현재 지원 상태는 아니다. 공식 hook, OpenShell full-process 배치,
Core relay, pre-LLM ingress와 terminal egress를 실제 버전에서 검증한 후 조사 기록과 E2E test
evidence를 추가한다. OpenClaw는 현재 구현 및 검증 범위에서 제외한다.

## 금지되는 승격 근거

- MCP server 등록 가능
- optional plugin callback 존재
- prompt에서 masking tool을 호출하라는 지시
- Agent가 output hook을 대부분 호출한다는 문서
- 일부 shell tool만 sandbox 내부 실행
- 수동 happy-path demo 성공

이 항목만으로는 강제 경계와 fail-closed behavior가 증명되지 않는다.

## 필수 smoke/negative test

- raw canary가 Agent input/LLM request/log에 없음
- Gateway를 건너뛴 direct input 거부
- masking/Vault/Core/OpenShell 실패 시 Agent 호출 없음
- key/Vault filesystem 접근 거부
- host-only/reveal channel 접근 거부
- direct provider/미허용 endpoint 차단
- incomplete streaming marker가 사용자에게 노출되지 않음
- reveal plaintext가 Agent/history로 되돌아가지 않음

검증 결과는 Agent 이름, version, OS, OpenShell version/policy와 함께 기록한다.
