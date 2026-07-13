# Agent MCP Bridge Tool Contract

이 문서는 OpenShell sandbox 내부의 무상태 Agent MCP Bridge가 노출하는 stdio MCP tool 계약을
정의한다. Gateway ingress, Reveal Coordinator, partial authority와 Fusion Sink는 이 MCP tool 목록에
포함하지 않는다.

관련 결정:

- [`1-2. mcp-privacy-core-boundary.md`](1-2.%20mcp-privacy-core-boundary.md)
- [`1-3. authority-channel-separation.md`](1-3.%20authority-channel-separation.md)
- [`1-4. handle-vault-contract.md`](1-4.%20handle-vault-contract.md)

## 경계

- MCP Bridge는 OpenShell Hermes Agent의 자식 stdio 프로세스다.
- Bridge는 stateless이며 secret key, Vault와 plaintext를 보유하지 않는다.
- Bridge는 Hermes와 같은 비신뢰 권한 영역이며 별도 보안 주체가 아니다.
- 모든 tool은 sandbox가 사용할 수 있는 session-scoped agent capability로 agent-safe Core interface에
  중계된다. Hermes가 같은 요청을 직접 보내도 추가 권한을 얻지 않아야 한다.
- `role`, `scope` 또는 session identity를 tool argument로 받아 권한을 상승시키지 않는다.
- Core 연결 실패 시 tool call을 실패시키고 local fallback을 사용하지 않는다.
- Bridge executable identity, process path와 capability 기밀성을 authorization 근거로 사용하지 않는다.

## Tool 목록

초기 namespace는 handle 기반 공개 연산만 제공한다.

| Tool | 입력 | 출력 |
|---|---|---|
| `fhe.handle_info` | `handle` | 공개 가능한 kind/type/allowed-ops 최소 metadata |
| `fhe.op_sum` | `handles[]` | `resultHandle` |
| `fhe.op_add` | `leftHandle`, `rightHandle` | `resultHandle` |
| `fhe.op_sub` | `leftHandle`, `rightHandle` | `resultHandle` |
| `fhe.op_scale` | `handle`, 정책상 공개 `factor` | `resultHandle` |
| `fhe.op_mul` | `leftHandle`, `rightHandle` | `resultHandle` |

Core는 session, handle kind, type, key/context, shape, allowed operation, depth와 quota를 검증한 뒤
결과 ciphertext를 저장하고 opaque result handle을 반환한다.

## 제공하지 않는 Tool

- `pii.mask_text`
- `pii.detect_ambiguous`
- `pii.resolve_markers`
- `fhe.encrypt_*`
- `fhe.decrypt_*`
- `fhe.load_public_context`
- `fhe.export_*`
- `vault.list`, `vault.read`, `vault.write`
- `reveal.*`

PII masking/encryption은 Gateway의 host-only Core interface가 수행한다. Reveal은 Coordinator가
승인하고 PC·스마트폰 partial authority가 모두 참여한 뒤 지정된 Fusion Sink에서만 수행한다.

## 예시

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"external-agent","version":"0"}}}
```

```json
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"fhe.op_scale","arguments":{"handle":"opaque-input-handle","factor":2}}}
```

```json
{"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"{\"resultHandle\":\"opaque-result-handle\"}"}]}}
```

## 거부 조건

- 평문 민감값 또는 raw ciphertext 제출
- unknown/cross-session/expired handle
- key/context/type/shape 불일치
- 비공개 factor 또는 허용되지 않은 operation
- quota, depth, payload 크기와 timeout 초과
- Core session/capability 누락 또는 폐기
- result ciphertext 저장 실패

오류 응답은 원문, ciphertext, Vault path와 내부 key/context material을 포함하지 않는다.

## 필수 검증

- initialize, tools/list와 tools/call stdio round-trip
- 제공하지 않는 decrypt/reveal/mask tool이 목록에 없음
- raw plaintext/ciphertext와 cross-session handle 거부
- Bridge restart 후 살아 있는 Core session 재연결
- Hermes가 Bridge request/capability를 복제해도 forbidden operation과 다른 session 접근 거부
- Core 종료 후 이전 handle 거부
- malformed JSON-RPC, oversize message, timeout과 cancellation
- stdout protocol 순수성 및 stderr redaction
