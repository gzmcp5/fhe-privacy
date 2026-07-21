# Design Open Decisions

이 문서는 FHE-Privacy가 기능 개발에 들어가기 전에 닫아야 할 설계 공백을 추적한다. 한 번에 하나의
결정만 검토하며, 결론과 근거가 관련 보안 문서에 반영되기 전에는 `decided`로 표시하지 않는다.

현재 문서는 구현 완료 목록이 아니다. 모든 항목은 설계 검토 상태이며 `feature_list.json`의 기능 상태는
검증 전까지 `not_started`를 유지한다.

## 상태

| 상태 | 의미 |
|---|---|
| `open` | 선택지와 영향 분석이 필요함 |
| `investigating` | 현재 하나의 설계 항목을 조사 중임 |
| `decided` | 결정, 근거, 위협과 검증 기준이 관련 문서에 반영됨 |
| `deferred` | 초기 제품 비범위와 안전한 기본 거부 동작을 정함 |

## 설계 완료 기준

기능 구현 시작 전 다음 조건을 만족해야 한다.

1. 아래 P0 결정이 모두 `decided` 또는 안전한 `deferred` 상태다.
2. 각 결정은 관련 `docs/1-*.md`의 불변식, 정상 흐름, fail-closed와 완료 검증에 반영돼 있다.
3. 프로세스·권한·IPC와 상태 전이가 문서로 연결돼 있다.
4. 각 보안 주장에 대응하는 negative test와 evidence 위치가 정의돼 있다.
5. 문서와 draw.io의 구성요소 이름, 실행 단위와 데이터 흐름이 일치한다.
6. 미구현·미검증 항목을 지원 완료로 표시하지 않는다.

## 검토 순서

WIP는 하나만 유지한다.

| 순서 | ID | 결정 | 우선순위 | 상태 |
|---|---|---|---|---|
| 1 | DOD-001 | Exact secret/file DEK의 2-of-2 threshold envelope primitive | P0 | investigating |
| 2 | DOD-002 | 파일 업로드·재시작에서 스마트폰 참여 시점과 DEK 수명 | P0 | open |
| 3 | DOD-003 | 프로세스·supervisor·OS identity·IPC manifest | P0 | open |
| 4 | DOD-004 | 세션·Vault·encrypted object store 통합 상태 모델 | P0 | open |
| 5 | DOD-005 | 파일 형식별 parser와 extraction coverage profile | P0 | open |
| 6 | DOD-006 | Output Document IR와 local renderer 계약 | P0 | open |
| 7 | DOD-007 | PII ambiguity·locale·사용자 확인 정책 | P0 | open |
| 8 | DOD-008 | Hermes/OpenShell secure adapter 강제 가능성 | P0 | open |
| 9 | DOD-009 | Protocol schema, error, retry와 idempotency | P1 | open |
| 10 | DOD-010 | 로그·audit·quota·retention 수치 | P1 | open |
| 11 | DOD-011 | 장치 분실, rotation과 recovery 정책 | P1 | open |
| 12 | DOD-012 | 플랫폼·배포·upgrade/migration 범위 | P1 | open |

첫 검토 대상은 **DOD-001 하나뿐**이다. DOD-001이 닫히기 전에는 다음 항목을 `investigating`으로
바꾸지 않는다.

## 전체 설계 지도

12개 결정은 독립 목록이 아니라 다음 순서로 제품의 보안 경계를 완성한다.

```text
[암호와 키]
DOD-001 DEK 2-of-2 보호 방식
    -> DOD-002 생성·parsing·reopen 동안 DEK 수명
    -> DOD-011 장치 등록·교체·분실·복구

[실행과 데이터]
DOD-003 process/권한/IPC 경계
    -> DOD-004 object·Vault·IR·handle 저장 상태
    -> DOD-009 message·retry·idempotency protocol

[파일과 개인정보]
DOD-005 입력 format·parser coverage
    -> DOD-007 PII 판정·모호성·사용자 확인
    -> DOD-006 출력 IR·local reveal·파일 생성

[제품 강제와 운영]
DOD-008 Hermes/OpenShell 우회 차단 가능성
    -> DOD-010 quota·timeout·retention·audit
    -> DOD-012 플랫폼·배포·upgrade·migration
```

의존 관계가 있다고 해서 뒤 항목을 미리 결정하지는 않는다. 앞 DOD에서 만든 불변식과 용어를 뒤 DOD가
입력으로 사용하며, 뒤에서 발견한 제약이 앞 결정을 무효화하면 상태를 다시 `investigating`으로 돌리고
근거를 갱신한다.

## P0 — 구현 전 필수 결정

### DOD-001 — 2-of-2 threshold envelope primitive

**상태:** `investigating`

Exact secret과 파일별 AEAD DEK를 보호하는 구체적인 2-of-2 primitive와 protocol을 확정한다.

결정할 질문:

- 어떤 threshold cryptography primitive와 검증된 library/backend를 사용하는가?
- PC와 스마트폰이 complete wrapping/reveal secret을 만들지 않고 어떻게 key material을 생성하는가?
- Wrap, partial unwrap과 fusion request의 입력·출력 형식은 무엇인가?
- Ciphertext/object/session/destination/policy를 associated data에 어떻게 binding하는가?
- Nonce, replay, rollback, key-set mismatch와 malformed share를 어떻게 거부하는가?
- Envelope version, rotation과 migration은 어떻게 식별하는가?
- 한 장치 또는 host memory에서 complete long-lived secret이 생성되지 않음을 어떻게 검증하는가?

#### 현재까지 정리된 개념과 후보 설계

아래 내용은 DOD-001의 최종 결정이 아니라 현재 검토 중인 기준안이다. 구현을 시작하기 전에 primitive,
library/backend, wire schema와 negative test를 추가 검증해야 한다.

##### 한눈에 보는 전체 그림

DOD-001이 해결하려는 문제는 **암호화된 파일이나 exact secret의 실제 복호키(DEK)를 PC 또는 스마트폰
한쪽만으로는 얻을 수 없게 만드는 것**이다. 데이터 자체는 빠르고 검증된 대칭키 방식인 AEAD로
암호화하고, 그 대칭키인 DEK만 PC와 스마트폰의 2-of-2 통제 아래 둔다.

```text
데이터 보호 계층                              DEK 보호 계층

평문 파일/exact secret                        object별 무작위 DEK
        |                                             |
        | AEAD 암호화                                | XOR로 2개 share 생성
        v                                             v
암호화된 object                              PC share       Phone share
                                                  |              |
                                            PC 공개키로      Phone 공개키로
                                            HPKE 암호화      HPKE 암호화
                                                  |              |
                                                  +------ 저장 --+

복원할 때: PC 승인 + Phone 승인
        -> 각 장치가 자기 share만 복호
        -> 승인된 local Fusion Sink에서 두 share 결합
        -> DEK를 짧게 재구성
        -> object를 AEAD 복호
        -> 허용된 local-only 목적지로만 평문 전달
```

핵심은 두 종류의 암호화를 구분하는 것이다.

1. **데이터 암호화:** DEK가 파일 또는 record를 AEAD로 암호화한다.
2. **DEK 통제:** DEK를 PC share와 Phone share로 나누고, 각 share는 해당 장치의 HPKE 공개키로 다시
   암호화해 보관한다.

PC share와 Phone share가 DEK를 암호화하는 것이 아니다. 두 share는 **DEK 자체를 나눈 조각**이고,
HPKE key pair가 각 조각을 저장·전송 중 보호한다. 두 조각이 승인된 Fusion Sink에 함께 도착해야만
원래 DEK가 잠시 재구성된다.

##### 적용 범위와 비적용 범위

DOD-001은 다음 두 대상의 **저장 상태(at rest) DEK 보호와 승인된 복원 방식**을 결정한다.

- 업로드 원본 파일: 파일마다 하나의 독립적인 file DEK로 AEAD 암호화한다.
- 계산하지 않는 exact secret: 민감 record마다 하나의 독립적인 record DEK로 AEAD 암호화한다.

다음 문제는 DOD-001만으로 해결하지 않는다.

- Gateway가 최초 입력을 받는 순간의 평문: trusted ingress가 암호화하려면 이 순간에는 평문과 DEK를
  memory에서 볼 수밖에 없다. 완전히 침해된 Gateway로부터 생성 시점 평문을 보호한다는 주장은 하지 않는다.
- 파일 parser에 복호 stream을 제공하는 시점, DEK memory 수명, crash/restart와 스마트폰 offline 동작:
  DOD-002에서 결정한다.
- 암호화된 object, envelope, metadata와 IR의 원자적 저장 및 삭제: DOD-004에서 결정한다.
- FHE ciphertext의 partial decrypt: 기존 FHE 2-of-2 reveal 영역이며 DEK envelope와 별도 protocol이다.

##### 참여자와 각자가 아는 정보

| 참여자 | 역할 | 볼 수 있는 정보 | 가져서는 안 되는 정보 |
|---|---|---|---|
| Trusted Gateway | object별 DEK 생성, AEAD 암호화, DEK 분할, share HPKE 암호화 | 입력 시점 평문과 일시적 DEK/share, 장치 공개키 | 장기 보관된 평문 DEK, 장치 HPKE 비밀키 |
| Encrypted Object Store | 암호화된 파일/record와 envelope 저장 | ciphertext, 암호화된 share, 최소 metadata | 평문 object, 평문 DEK/share |
| PC Partial Authority | PC 사용자·장치 승인 후 PC share 복호 | PC HPKE 비밀키, 승인된 요청의 PC share | Phone share, 단독으로 완성된 DEK |
| Phone Partial Authority | 스마트폰 승인 후 Phone share 복호 | Phone HPKE 비밀키, 승인된 요청의 Phone share | PC share, 단독으로 완성된 DEK |
| Approved Fusion Sink | 승인·binding을 검증하고 두 share를 결합해 local reveal 수행 | 승인 순간의 두 share, 일시적 DEK와 허용된 평문 | 장기 보관 DEK, Agent/LLM 방향 평문 egress |
| Agent/LLM/MCP Bridge | 마스킹된 값과 opaque handle만 처리 | masked content, handle, 공개 FHE context | 원본 평문, DEK, share, 장치 비밀키 |

##### 용어 사전

| 용어 | 이 설계에서의 의미 |
|---|---|
| Plaintext | 암호화 전 원본 파일 또는 민감값. 비신뢰 Agent/LLM으로 보내지 않는다. |
| Ciphertext | 암호화된 데이터. 키 없이는 원본을 읽을 수 없다. |
| Exact secret | 원래 값 그대로 복원해야 하지만 동형 연산은 필요하지 않은 민감값이다. 주민등록번호, 전화번호, 계좌번호, API token, password, 상세 주소와 의료 식별자 등이 예다. |
| DEK | Data Encryption Key. 파일 또는 record의 실제 내용을 암호화하는 object별 무작위 대칭 비밀키다. 공개키가 아니다. |
| AEAD | Authenticated Encryption with Associated Data. 평문을 숨기면서 변조도 검출하고, object ID 같은 비밀이 아닌 context를 암호문에 결속하는 대칭키 암호 방식이다. |
| Associated Data(AAD) | 암호화하지는 않지만 ciphertext와 함께 인증하는 metadata다. 다른 object/session/destination으로 ciphertext를 바꾸어 끼우는 공격을 막는 데 사용한다. |
| Nonce | 같은 키로 암호화할 때 요구되는 고유값이다. 재사용 조건은 선택한 AEAD algorithm에 따라 정하며, 일반 metadata처럼 비밀일 필요는 없다. |
| Envelope encryption | 데이터는 DEK로 암호화하고, 작은 DEK는 별도의 보호 계층으로 감싸 보관하는 키 계층이다. 여기서는 DEK를 2-of-2 share로 나누어 보호한다. |
| Master key/KEK | 일반 envelope encryption에서 DEK를 감싸는 상위 키다. KEK는 Key Encryption Key의 약자다. 단일 KEK는 한 보유자가 모든 DEK를 풀 수 있어 본 설계의 기준 후보로 사용하지 않는다. |
| Secret sharing | 하나의 secret을 여러 조각으로 나누어 정해진 수의 조각이 모여야 복원되게 하는 기법이다. 이 후보에서는 DEK를 PC share와 Phone share로 나눈다. |
| Share | Secret sharing으로 얻은 조각이다. 암호화 키가 아니라 원래 DEK를 복원하는 데 필요한 입력이다. |
| XOR | 같은 길이의 두 bit열을 결합하는 연산이다. `pc_share XOR phone_share = DEK`가 되도록 두 share를 만든다. |
| 2-of-2 | 두 참여자 중 두 명 모두가 있어야 복원할 수 있다는 threshold 정책이다. 한 장치만으로는 복원할 수 없다. |
| Threshold cryptography | 전체 `n`개 참여자 중 최소 `t`개가 있어야 암호 연산을 완료하게 하는 암호 기술의 총칭이다. `2-of-2`에서 `t=2`, `n=2`다. |
| Threshold PKE | 하나의 joint public key와 분산 private-key share를 이용하는 엄밀한 threshold public-key encryption이다. 현재 XOR+HPKE 후보와는 구조가 다르다. |
| HPKE | Hybrid Public Key Encryption. 수신자의 공개키로 작은 payload를 암호화하고 해당 비밀키 보유자만 복호하게 하는 표준 방식이다. 여기서는 각 DEK share를 해당 장치에 안전하게 전달·보관하는 데 사용한다. |
| HPKE key pair | 장치별 공개키와 비밀키 쌍이다. Gateway는 공개키로 share를 암호화하고, 해당 장치만 비밀키로 자기 share를 복호한다. FHE key/share와 별개다. |
| Partial Authority | PC 또는 Phone에서 자기 share만 복호하고 사용자·장치 승인을 확인하는 신뢰 주체다. |
| Fusion Sink | 두 장치가 승인한 share를 결합해 DEK를 재구성하고 local-only 복호를 수행하는 허용된 목적지다. |
| Wrap/unwrap | 키 같은 작은 secret을 보호 형태로 만들거나 되돌리는 일반 용어다. 이 후보에서는 엄밀히 `DEK split + share HPKE encryption`과 `share HPKE decryption + DEK reconstruction`으로 표현한다. |
| SMPC | 여러 참여자가 각자의 입력을 공개하지 않고 공동 계산하는 일반 기술이다. Secret sharing을 사용할 수 있지만, share 결합 지점이 DEK를 보는 현재 후보 자체를 일반 목적 SMPC라고 부르지 않는다. |

##### 키와 데이터의 수명

- **DEK(Data Encryption Key)**는 파일 또는 exact-secret record의 실제 내용을 AEAD로 암호화하는 무작위
  대칭 비밀키다. 공개키가 아니며 Agent, LLM, MCP Bridge, OpenShell, 로그, 영속 metadata와 crash dump에
  노출하면 안 된다.
- 파일마다 독립적인 file DEK를 사용하고 exact-secret record마다 독립적인 record DEK를 사용한다. 많은
  DEK가 생성되는 것은 의도된 envelope-encryption 구조이며, 한 키 유출의 영향 범위를 해당 object로
  제한한다. 32-byte DEK 백만 개의 원시 크기는 약 32 MB지만 실제 저장량에는 envelope와 metadata
  overhead가 추가되므로 DOD-004에서 산정한다.
- 큰 파일을 chunk 단위 AEAD로 암호화할 때는 기본적으로 하나의 file DEK와 chunk마다 고유한 nonce 및
  chunk index binding을 사용한다. 필요하면 file DEK에서 chunk subkey를 유도하되, chunk마다 별도 DEK를
  무조건 생성하지는 않는다.
- 일반적인 envelope encryption은 master key 또는 KEK(Key Encryption Key)가 DEK를 AES-KW, AEAD 또는
  KMS/HSM의 `WrapKey` 같은 방식으로 감싼다. 그러나 단일 master key 보유자가 모든 DEK를 단독 복구할
  수 있으므로 현재 제품의 2-of-2 요구에는 그대로 적용하지 않는다.
- DEK는 암호화 순간 trusted Gateway memory와 승인된 reveal 순간 Fusion Sink memory에만 짧게 존재할 수
  있다. 평문 DEK를 영속 보관하지 않으며, memory 수명·삭제·crash dump 통제는 DOD-002에서 확정한다.

##### 기준 후보 A — XOR 2-of-2 secret share와 장치별 HPKE

현재 권고 후보는 DEK 자체를 XOR 방식으로 2-of-2 분할하고, 각 share를 해당 장치의 독립된 HPKE
공개키로 암호화하는 방식이다.

```text
평문 파일/record
  -> object별 무작위 DEK로 AEAD 암호화
  -> 암호문

DEK
  -> pc_share = 무작위 32 bytes
  -> phone_share = DEK XOR pc_share
  -> HPKE(pk_pc_hpke, pc_share)
  -> HPKE(pk_phone_hpke, phone_share)
```

`pc_share XOR phone_share = DEK`이며 어느 한 share만으로는 DEK에 관한 정보를 얻을 수 없다. 여기서
**PC share와 Phone share는 DEK를 암호화하기 위한 키가 아니라 DEK를 둘로 나눈 조각**이다. 각 share를
보관·전송할 때 암호화하는 키는 별도의 장치별 HPKE 공개키다.

저장소에는 다음 항목만 둔다.

- AEAD로 암호화한 파일 또는 record
- PC HPKE 공개키로 암호화한 PC share
- Phone HPKE 공개키로 암호화한 Phone share
- 공개 가능하며 최소화된 envelope metadata

평문 DEK와 평문 share는 저장하지 않는다. 후보 metadata/binding 필드는 `envelope_version`,
`algorithm_suite`, `envelope_id`, `object_id` 또는 `record_id`, `session_id`, `key_set_id`, `secret_type`,
`destination`, `policy_version`, `created_at`, `expiry`와 두 encrypted share다. 정확한 wire/storage schema는
추가 결정 대상이다.

Reveal 후보 흐름은 다음과 같다.

```text
PC Partial Authority
  -> HPKE로 PC share 복호

Phone Partial Authority
  -> HPKE로 Phone share 복호

두 장치의 승인된 session/destination-bound share
  -> 승인된 Fusion Sink
  -> XOR로 DEK 재구성
  -> AEAD로 파일/record 복호
```

HPKE(Hybrid Public Key Encryption)의 발신자는 share를 암호화하는 Gateway다. 수신자는 각각 PC Partial
Authority와 Phone Partial Authority이며, 각 장치는 서로 다른 HPKE key pair를 가진다. Fusion Sink는
HPKE의 직접 수신자가 아니라 두 authority가 승인 후 내보낸 share의 목적지다. HPKE key pair는 FHE의
PC/Phone secret-key share와 별도다.

##### 처음부터 끝까지의 수명주기

**0. 장치 등록(enrollment)**

1. PC Partial Authority와 Phone Partial Authority가 각자 HPKE key pair를 만든다.
2. 각 HPKE 비밀키는 생성된 장치 밖으로 내보내지 않고 장치의 OS secure storage 또는 검증된 key store에
   보관한다. 구체적인 저장 backend는 DOD-001의 library/backend 결정에 포함한다.
3. Gateway에는 인증된 PC/Phone HPKE 공개키와 두 키를 묶는 `key_set_id`만 등록한다.
4. FHE용 PC/Phone share와 HPKE key pair는 목적·형식·rotation을 분리한다. 서로 재사용하지 않는다.

**1. 파일 또는 exact secret 저장**

1. Trusted Gateway가 object마다 새 무작위 DEK를 생성한다.
2. Gateway가 DEK와 AEAD를 사용해 평문을 암호화한다. 큰 파일은 chunk마다 고유 nonce와 순서를
   인증하여 삭제·재정렬·중복·교체를 탐지할 수 있게 한다.
3. Gateway가 무작위 `pc_share`를 만들고 `phone_share = DEK XOR pc_share`를 계산한다.
4. Gateway가 PC 공개키로 `pc_share`를, Phone 공개키로 `phone_share`를 HPKE 암호화한다. Object,
   session, key set, destination과 policy 정보를 HPKE `info`/AAD 및 envelope metadata에 결속한다.
5. 암호화된 object, 암호화된 두 share와 최소 metadata를 저장한다. 어느 하나라도 저장에 실패하면
   handle을 발급하지 않고 불완전 object를 정리하는 fail-closed transaction이 필요하다(DOD-004).
6. Gateway가 평문 DEK와 share를 가능한 즉시 memory에서 제거한다. 정확한 최대 수명은 DOD-002에서 정한다.

**2. 승인된 local reveal**

1. Reveal Coordinator가 `object_id`, `session_id`, `key_set_id`, 요청 목적지, policy와 expiry가 결속된
   요청을 만든다.
2. PC와 스마트폰은 같은 요청을 독립적으로 검증하고 각각 사용자·장치 승인을 수행한다.
3. PC는 자기 HPKE 비밀키로 PC share만 복호하고, Phone은 자기 비밀키로 Phone share만 복호한다.
4. 두 authority는 share를 일반 응답이나 Agent 경로로 보내지 않고, 승인된 session/destination-bound
   reveal-only channel을 통해 지정된 Fusion Sink로만 보낸다.
5. Fusion Sink가 두 승인과 binding의 일치를 확인한 뒤 `DEK = pc_share XOR phone_share`로 일시적으로
   재구성한다.
6. Fusion Sink가 암호문과 AAD를 검증하면서 AEAD 복호하고, 평문을 trusted UI, local renderer 또는
   승인된 local consumer에만 전달한다. Agent/LLM 방향 egress는 금지한다.
7. 작업 종료·실패·timeout 시 Fusion Sink가 DEK, share와 평문 buffer를 제거한다.

**3. 한 장치만 있거나 요청이 변조된 경우**

- PC share 또는 Phone share 하나만으로 DEK를 계산할 수 없으므로 reveal을 거부한다.
- 장치가 offline, 승인을 거부하거나 timeout이면 single-key fallback 없이 실패한다.
- `object_id`, session, destination, policy, key set 또는 expiry가 다르면 share 결합을 거부한다.
- Share/ciphertext가 손상되었거나 다른 object의 share로 교체되면 HPKE/AEAD 인증 또는 binding 검증에서
  실패해야 한다.
- 과거의 유효 요청이나 share를 다시 보내는 replay, 이전 key set으로 되돌리는 rollback도 거부해야 한다.
  구체적인 counter/state와 protocol은 DOD-001의 미결정 항목이다.

이 후보는 일반 목적 SMPC 시스템을 도입한다는 뜻이 아니다. Secret sharing은 SMPC와 threshold
cryptography에서도 쓰이는 독립 primitive지만 여기서는 DEK를 둘로 나누는 데만 사용한다. Fusion Sink가
두 share로 DEK를 재구성하고 평문을 보므로, Fusion Sink조차 DEK를 보지 않게 하는 일반 SMPC protocol은
아니다.

##### FHE 2-of-2와의 관계

FHE reveal과 DEK envelope는 **동일한 2-of-2 참여 정책**을 공유하지만 암호 방식과 키는 다르다.

| 구분 | FHE reveal | DEK envelope 기준 후보 |
|---|---|---|
| 보호 대상 | FHE ciphertext | 파일/record용 대칭 DEK |
| 키 구조 | joint public context와 PC/Phone FHE secret share | XOR로 분할한 DEK share와 장치별 HPKE key pair |
| 장치 동작 | partial decrypt 후 fusion | HPKE share 복호 후 XOR reconstruction |
| 공통점 | PC와 스마트폰 모두 참여해야 reveal 가능 | PC와 스마트폰 모두 참여해야 DEK 복구 가능 |

따라서 “동형암호와 동일한 방식을 적용한다”가 아니라 “동일한 2-of-2 승인 불변식을 서로 다른
primitive로 구현한다”가 정확하다.

##### `threshold` 용어와 대안

Threshold cryptography의 `threshold`는 전체 `n`명 중 최소 `t`명이 참여해야 연산을 완료할 수 있다는
뜻이다. 예를 들어 2-of-2는 두 참여자가 모두 필요하고 2-of-3은 세 참여자 중 둘이 필요하다. 엄밀한
threshold public-key encryption은 하나의 joint public key와 분산된 private-key share를 사용해 partial
decrypt를 결합한다.

기준 후보 A는 joint public key를 쓰는 엄밀한 threshold PKE가 아니다. 문서와 API에서는 혼동을 피하기
위해 **2-of-2 secret-shared DEK envelope**라는 용어를 우선 사용한다. DOD-001에서 다음 대안을 비교한다.

| 대안 | 장점 | 주요 제약/기각 검토 사유 |
|---|---|---|
| A. XOR 2-of-2 share + 장치별 HPKE | 단순하고 표준 primitive 조합이며 장치별 독립 인증·교체가 가능 | Fusion Sink가 일시적으로 complete DEK를 보며 엄밀한 threshold PKE는 아님 |
| B. OpenFHE BFV/BGV multiparty로 DEK 보호 | FHE reveal과 유사한 joint-key/partial-decrypt 모델 | 파일 복호 경로에 비해 무겁고 스마트폰 backend가 아직 검증되지 않음 |
| C. Threshold ElGamal/ECDH KEM | 엄밀한 threshold PKE 의미에 가까움 | 검증된 cross-platform backend 선정이 필요하며 custom crypto 구현은 허용하지 않음 |

##### 아직 결정하지 않은 핵심 질문

DOD-001의 첫 결정은 “하나의 joint public key를 사용하는 엄밀한 threshold PKE가 반드시 필요한가,
아니면 XOR share와 장치별 HPKE를 조합한 2-of-2 secret-shared DEK envelope를 채택할 것인가”이다. 현재는
후자를 기준 후보로 권고하지만, backend 검증과 위협 분석이 끝나기 전에는 `decided`로 표시하지 않는다.

참고 표준과 구현 문서:

- [RFC 9180 — Hybrid Public Key Encryption](https://www.rfc-editor.org/rfc/rfc9180.html)
- [OpenFHE documentation](https://openfhe-development.readthedocs.io/en/latest/)
- [libsodium sealed boxes](https://libsodium.gitbook.io/doc/public-key_cryptography/sealed_boxes)

완료 조건:

- primitive와 protocol 선택 및 대안 기각 근거가 기록됨
- 메시지 sequence와 wire/storage schema가 정의됨
- one-share, replay, swap, rollback, corruption negative test가 정의됨
- [`1-6. cryptography-data-policy.md`](1-6.%20cryptography-data-policy.md)와
  [`threshold-fhe-reveal.md`](threshold-fhe-reveal.md)에 결정이 반영됨

### DOD-002 — 파일 DEK와 스마트폰 참여 시점

**상태:** `open`

파일 업로드 직후 local parser가 원본을 읽어야 하는 요구와 file DEK를 2-of-2 envelope로만 복구해야
하는 요구를 함께 만족하는 session model을 확정한다.

#### 이 결정이 필요한 이유

파일을 암호화해 보관하려면 Gateway가 업로드 순간 file DEK를 생성해야 하고, parser가 내용을
추출하려면 평문 stream을 읽어야 한다. 반면 저장된 file DEK를 다시 얻는 과정은 PC와 스마트폰이 모두
참여해야 한다. 생성 직후 parsing과 나중의 reopen을 구분하지 않으면 스마트폰 없이 DEK를 장시간
memory에 남기거나, 반대로 업로드마다 불필요한 스마트폰 승인을 요구하게 된다.

#### 용어와 범위

| 용어 | 의미 |
|---|---|
| Ingest session | 업로드 수신, 원본 암호화, parsing, CDIR 생성과 Gateway 검사를 묶는 제한 시간 작업 단위 |
| Hot DEK | 현재 trusted process memory에만 존재하는 평문 DEK |
| Sealed object | AEAD 암호문과 2-of-2 DEK envelope가 모두 영속 저장된 object |
| Reopen | process 종료 또는 session 만료 뒤 sealed object를 다시 복호해 읽는 동작 |
| Decrypting stream | 평문 임시 파일 없이 암호화 object를 순차 또는 제한적 seek 방식으로 읽게 하는 capability |
| Lease | 특정 object/session/parser/destination에 한정되고 만료되는 접근 권한 |

DOD-002는 스마트폰 승인 시점, DEK memory 수명, parser stream과 crash/offline 동작을 결정한다. Envelope
primitive는 DOD-001, 저장 transaction은 DOD-004, parser 형식은 DOD-005에서 결정한다.

#### 기준 후보 흐름

**최초 업로드의 동일 session parsing**

1. Gateway가 file DEK를 생성하고 업로드 bytes를 즉시 chunked AEAD로 암호화한다.
2. 같은 ingest session 안에서는 Gateway가 제한 시간 동안 hot DEK를 보유하고 isolated parser에
   object/session-bound decrypting stream capability를 제공한다.
3. Parser는 평문 경로를 받지 않고 stream만 읽어 extraction result와 coverage manifest를 반환한다.
4. Gateway가 CDIR 변환과 PII 검사를 마치면 hot DEK를 제거하고 session을 닫는다.
5. 이 흐름에서 스마트폰 참여를 업로드 필수 조건으로 할지, envelope 생성에 공개키만 사용하고 최초
   reopen부터 승인을 요구할지가 핵심 결정이다.

**Session 종료 후 reopen**

1. 저장된 encrypted object와 envelope를 조회한다.
2. DOD-001의 PC·Phone 2-of-2 승인으로 file DEK를 승인된 local sink에만 재구성한다.
3. 제한된 새 lease와 decrypting stream을 발급한다.
4. 완료·실패·timeout 시 stream, buffer와 DEK를 제거한다.

#### 기준 보안 불변식

- 평문 원본 또는 평문 DEK를 disk, swap, log, environment variable과 IPC metadata에 쓰지 않는다.
- Parser child에는 DEK 자체가 아니라 읽기 전용 decrypting stream capability만 제공한다.
- Session 종료 뒤 스마트폰 없는 reopen을 허용하지 않으며 single-device cache/fallback을 두지 않는다.
- Crash 뒤 memory에 있던 hot DEK는 복구하지 않는다. 저장 transaction이 완성된 object만 2-of-2로 reopen한다.
- 스마트폰 offline 정책은 명시적이어야 하며 보안을 낮추는 fallback으로 가용성을 회복하지 않는다.

결정할 질문:

- 스마트폰은 세션 시작, 파일 업로드, parser 실행 또는 재시작 복구 중 언제 참여하는가?
- Gateway가 새 DEK를 생성한 뒤 평문 DEK를 memory에 유지할 수 있는 최대 수명은 얼마인가?
- Parser에는 seekable decrypting stream을 누가 어떤 capability로 제공하는가?
- Gateway/Core crash 뒤 스마트폰 없이 parsing을 재개할 수 있는가?
- 스마트폰이 offline이면 업로드, parsing, 보관과 삭제 중 무엇을 허용하는가?
- 영속 보관 파일의 reopen과 사용자 승인은 어떤 상태 전이를 사용하는가?
- 최초 session에서 허용하는 hot DEK 최대 수명·byte limit·parser 횟수는 얼마인가?
- OS swap/core dump 방지와 best-effort memory zeroization을 어떤 플랫폼에서 어떻게 검증하는가?

완료 조건:

- 정상·offline·crash·restart·expiry sequence가 정의됨
- DEK의 memory/disk/envelope 위치와 수명이 각 상태에서 명확함
- plaintext temporary file 부재와 재시작 fail-closed test가 정의됨
- [`1-9. secure-file-ingress.md`](1-9.%20secure-file-ingress.md)에 반영됨

### DOD-003 — 프로세스와 IPC manifest

**상태:** `open`

각 컴포넌트의 executable, 부모·자식 관계, supervisor, OS identity, channel과 허용 데이터를 확정한다.

#### 이 결정이 필요한 이유

아키텍처 그림의 상자는 논리 컴포넌트일 수도 있고 독립 process, child process 또는 외부 runtime일 수도
있다. 실행 경계를 확정하지 않으면 어떤 process가 평문·키·Vault에 접근할 수 있는지, 누가 crash를
감지하고 재시작하는지, 어떤 IPC가 Agent에 노출되는지를 검증할 수 없다.

#### 용어

| 용어 | 의미 |
|---|---|
| Component | 하나의 책임을 나타내는 논리 단위. 반드시 별도 process라는 뜻은 아님 |
| Process | 독립 주소 공간과 OS process identity를 가진 실행 단위 |
| Child process | 부모가 생성하고 lifecycle을 관리하는 subprocess |
| Runtime | Hermes 또는 OpenShell처럼 workload 실행 환경과 lifecycle을 제공하는 시스템 |
| Supervisor | process 시작, health, 종료, restart와 dependency 순서를 관리하는 주체 |
| IPC | process 간 통신. stdio, UDS/named pipe, loopback HTTPS/mTLS 등이 후보 |
| OS identity | 사용자, UID/SID, sandbox label 등 OS가 접근 통제에 사용하는 실행 주체 |
| Capability | 특정 object와 동작에 한정된 위조 불가능하고 만료되는 권한 |

#### 기준 process model

| 실행 단위 | 형태 후보 | 부모/supervisor | 주요 권한 |
|---|---|---|---|
| Secure Gateway | 독립 trusted process | 제품 supervisor | Agent ingress/egress, masking orchestration; 장기 key 직접 소유 금지 |
| Privacy Core | 독립 host-only process | 제품 supervisor | Vault, policy와 handle 관리 |
| Public FHE Worker | 독립 또는 제한 child process | Privacy Core | 공개 FHE context와 ciphertext 연산만 허용 |
| Isolated Document Parser | 파일별 ephemeral child process | Secure Gateway | 한 object의 decrypting stream read와 extraction output write만 허용 |
| OpenShell runtime | 외부 sandbox runtime | OpenShell supervisor | Hermes workload 격리·network/filesystem policy 적용 |
| Hermes | sandbox workload main process | OpenShell runtime | 마스킹된 prompt/IR과 Agent tool orchestration만 허용 |
| MCP Bridge | Hermes child stdio process 후보 | Hermes | 허용 MCP schema 중계; plaintext/key/Vault 접근 금지 |
| Reveal Coordinator | 독립 trusted process 후보 | 제품 supervisor | PC/Phone 승인 조정; complete DEK/plaintext 보유 금지 |
| PC Partial Authority | 독립 host-only process | 제품 supervisor/OS | PC key/share와 partial operation |
| Phone Partial Authority | 스마트폰 app process | 모바일 OS | Phone key/share와 사용자 승인 |
| Renderer/Fusion Sink | ephemeral trusted process 후보 | Reveal Coordinator | 승인된 local reveal/render 동안만 DEK/plaintext 접근 |

표의 형태는 기준 후보이며 executable 수, 부모 관계와 동일 process 배치는 이 DOD에서 확정한다.

#### Channel 분류 기준

- **Agent-safe channel:** masked content, opaque handle, 공개 FHE context만 허용한다.
- **Host-only trusted channel:** policy/Vault control과 제한 capability를 허용하며 sandbox에서 접근할 수 없다.
- **Reveal-only channel:** 승인된 partial/share와 local plaintext를 지정 sink로만 전달한다.
- **Child stdio:** 부모·자식 한 쌍의 schema 메시지만 허용하고 inherited handle/environment를 최소화한다.

각 channel은 caller와 server OS identity, 인증 방식, 허용 message type, size/timeout, secret classification,
retry와 shutdown 동작을 manifest에 기록해야 한다.

결정할 질문:

- Secure Gateway, Privacy Core와 Public FHE Worker를 각각 독립 process로 둘 것인가?
- Gateway가 isolated parser child를 어떻게 생성·제한·종료하며 orphan을 누가 정리하는가?
- OpenShell runtime, Hermes workload와 Hermes child MCP Bridge의 실제 부모·자식 관계는 무엇인가?
- Reveal Coordinator, PC Partial Authority와 Renderer/Fusion Sink를 어느 process 경계로 분리하는가?
- Smartphone app process와 host 사이 device-authenticated channel은 누가 열고 인증하는가?
- Agent-safe HTTPS/mTLS, host-only UDS, reveal-only UDS와 stdio의 caller/server/owner는 누구인가?
- 시작·종료·crash·restart·dependency failure와 lease expiry를 어느 supervisor가 처리하는가?
- 각 child가 상속할 수 있는 file descriptor/handle, environment와 working directory는 무엇인가?
- Process별 network/filesystem/syscall 권한과 Agent-safe/reveal-only channel을 어떻게 물리적으로 분리하는가?

완료 조건:

- 별도 `process-runtime-manifest.md`가 생성됨
- 각 프로세스의 plaintext/key/share/Vault 접근 행렬이 정의됨
- 실행 순서와 장애 전파 규칙이 정의됨
- [`1. architecture-component-flow.drawio`](1.%20architecture-component-flow.drawio)와 일치함

### DOD-004 — 통합 상태와 저장 transaction

**상태:** `open`

In-memory Session Vault, encrypted original object store, metadata DB, Canonical Document IR과 PII record의
상태를 하나의 transaction/lifecycle model로 통합한다.

#### 이 결정이 필요한 이유

원본 ciphertext만 저장되고 envelope나 metadata가 누락되면 복구 불가능한 orphan이 생긴다. 반대로
metadata나 handle이 먼저 공개되면 아직 검증되지 않았거나 불완전한 object를 Agent가 참조할 수 있다.
Session 종료, crash, disk full과 사용자 삭제에서도 모든 저장소가 같은 object 상태를 이해해야 한다.

#### 저장 요소와 용어

| 요소 | 내용 | 민감도 |
|---|---|---|
| Encrypted object | AEAD로 암호화된 원본 파일 또는 exact-secret record | ciphertext지만 접근 제한 필요 |
| Envelope | 암호화된 PC/Phone DEK share와 algorithm/key-set metadata | 보안 metadata |
| Object manifest | 크기, chunk, digest, format, parser/coverage 상태 | 최소 공개 metadata |
| Canonical Document IR | parser가 추출한 구조와 text; Gateway 검사 전에는 평문 민감정보 포함 가능 | trusted-only |
| Vault record | 원문 민감값, marker/handle mapping과 정책 정보 | 최고 민감도 |
| Agent handle | Agent가 원문 대신 사용하는 opaque reference | Agent-safe지만 session-bound |
| Quarantine | 검증 실패·불완전 object의 격리 상태 | Agent 비가시 |
| Tombstone | 삭제됨을 나타내며 재노출을 막는 최소 기록 | 비밀값 포함 금지 |

#### 기준 상태 모델

```text
RECEIVING
  -> SEALED              원본 ciphertext + envelope 저장 완료
  -> PARSING             parser lease 활성
  -> INSPECTED           coverage 검증과 CDIR 생성 완료
  -> GATEWAY_APPROVED    PII 검출·마스킹 완료
  -> COMMITTED           metadata/Vault/handle 원자적 공개

어느 단계든 실패
  -> QUARANTINED 또는 ABORTING
  -> DELETED/TOMBSTONED
```

상태 이름은 후보이며 중요한 불변식은 `COMMITTED` 전에는 Agent handle을 발급하지 않는 것이다.

#### 기준 commit·복구 원칙

1. Object ID와 transaction ID를 먼저 예약하되 Agent에는 공개하지 않는다.
2. 암호화 object와 envelope를 임시 namespace에 내구성 있게 기록하고 digest/길이를 검증한다.
3. Parser coverage, CDIR, PII/Vault 결과를 transaction에 연결한다.
4. Metadata DB의 commit record와 object namespace publish를 원자적 또는 재실행 가능한 protocol로 묶는다.
5. 마지막 단계에서만 handle을 활성화한다.
6. 시작 시 journal을 scan해 incomplete transaction을 재개하지 말고 안전하게 격리·정리하거나, 명시적으로
   증명된 idempotent recovery만 수행한다.
7. 사용자 삭제는 handle revoke를 먼저 수행하고 ciphertext/envelope 삭제와 cryptographic erasure evidence를
   남긴다. Tombstone에는 원문, DEK, share와 원본 filename을 남기지 않는다.

결정할 질문:

- Object bytes, manifest, metadata, IR와 handle을 어떤 순서로 commit하는가?
- 일부 commit, disk full, crash와 metadata corruption에서 orphan을 어떻게 찾고 정리하는가?
- Session 종료, TTL 만료, 사용자 삭제와 process crash는 각각 어떤 정리 동작을 수행하는가?
- Persistent file과 session-only file을 어떻게 구분하는가?
- Cryptographic erasure 완료를 어떤 evidence로 남기는가?
- Quarantine object의 상태, 접근 주체와 TTL은 무엇인가?
- DB transaction과 filesystem/object-store rename 사이의 원자성 간극을 어떤 journal로 복구하는가?
- Backup, snapshot과 OS 휴지통이 retention·cryptographic erasure 주장에 포함되는가?

완료 조건:

- 별도 state machine과 atomicity invariant가 정의됨
- 모든 failure transition에 Agent 호출/handle 발급 여부가 명시됨
- crash-recovery, orphan cleanup과 rollback negative test가 정의됨
- [`1-4. handle-vault-contract.md`](1-4.%20handle-vault-contract.md)와 파일 문서에 반영됨

### DOD-005 — 파일 parser와 coverage profile

**상태:** `open`

지원 형식마다 “모든 Agent-bound text를 완전하게 추출했다”는 판정 규칙을 실행 가능한 profile로 만든다.

#### 이 결정이 필요한 이유

Parser가 읽지 못한 text, comment, hidden part나 embedded object가 그대로 Agent/LLM으로 전달되면 Gateway의
PII 검사를 우회한다. 따라서 “library가 파일을 열었다”가 아니라, 지원 profile에 정의된 모든
Agent-bound content를 추출했고 미확인 content가 없음을 증명해야 한다. OCR은 지원하지 않는다.

#### 지원 형식 기준 후보

| 형식 | 초기 지원 후보 | 주요 검증 대상 |
|---|---|---|
| Plain text (`.txt`) | 지원 | UTF-8/허용 encoding, BOM, NUL, line/size limit |
| Markdown (`.md`, `.markdown`) | 지원 | front matter, link/image alt/title, HTML block, code block, include 확장 금지 |
| CSV/TSV | 지원 | encoding, delimiter/quote, formula-like cell, row/column/field limit |
| JSON | 지원 | UTF-8, duplicate key, depth/number/string limit, scalar text traversal |
| DOCX | 지원 | OOXML text, table, header/footer, footnote/endnote, comment 등 허용 part의 coverage |
| Text-based PDF | 제한 지원 | page별 text mapping, font/encoding, action/attachment, image-only 또는 혼합 상태 탐지 |
| HTML | 보류 후보 | active content, external resource와 parsing ambiguity 때문에 별도 profile 필요 |
| RTF/ODT/XLSX/PPTX | 초기 비지원 후보 | format별 hidden content와 구조 coverage를 별도 설계해야 함 |
| Image/scanned PDF | 비지원 | OCR을 제공하지 않으며 text coverage를 증명할 수 없음 |

Extension과 MIME sniffing이 일치해야 하며 password-protected, encrypted, signed-with-unsupported-transform,
embedded archive/object, macro/active content와 polyglot은 기본 거부한다. 최종 목록과 세부 profile은 이
DOD에서 결정한다.

#### Canonical Document IR과 coverage manifest

Parser는 마스킹하지 않는다. Isolated parser는 허용된 bytes를 읽어 text와 구조를 **Canonical Document
IR(CDIR)**로 정규화하고, 무엇을 검사했는지 coverage manifest를 함께 반환한다. Secure Gateway가 CDIR의
모든 Agent-bound text field에 PII 검출·마스킹을 적용한 뒤에만 Agent-safe IR을 만든다.

Coverage manifest 기준 필드는 `format_profile_version`, parser/library version, detected MIME, object/page/
part/cell 수, visited node/part 목록, extracted text count, ignored decorative item, warning, unsupported node,
truncation 여부와 content digest다. `unknown`, `unsupported`, `truncated`, timeout 또는 limit 초과가 있으면
Agent 전달을 fail-closed한다.

#### Parser 격리 기준

- 파일별 ephemeral child process에서 network를 차단하고 read-only decrypting stream만 제공한다.
- Temp plaintext file, inherited Vault/key handle과 임의 host filesystem 접근을 금지한다.
- CPU, memory, wall time, decompressed bytes, recursion, page/part/cell/node 수를 제한한다.
- Parser crash와 malformed input은 Gateway crash로 전파하지 않고 해당 object를 격리한다.
- Parser output은 신뢰하지 않고 schema, size, ordering과 digest를 Gateway가 다시 검증한다.

결정할 질문:

- TXT/Markdown/CSV/TSV/JSON의 encoding, grammar, extension과 quota는 무엇인가?
- DOCX의 필수/허용/거부 OOXML part와 relationship은 무엇인가?
- PDF의 허용 object, action, filter, font/text mapping과 page 상태는 무엇인가?
- 장식 image와 `MIXED_UNVERIFIED` PDF를 어떻게 판정하는가?
- 사용할 parser library/version과 sandbox resource limit은 무엇인가?
- Parser warning과 unknown node를 어떤 code로 반환하는가?
- 각 format에서 Agent-bound text와 무시 가능한 decorative content의 경계를 어떻게 정의하는가?
- 지원 library의 CVE 대응, version pinning과 corpus 회귀 검증 주기는 무엇인가?

완료 조건:

- format별 versioned profile과 coverage manifest schema가 정의됨
- supported/malformed/active/embedded/OCR-required corpus가 정의됨
- parser escape, decompression bomb, timeout과 truncation test가 정의됨
- [`1-9. secure-file-ingress.md`](1-9.%20secure-file-ingress.md)에 반영됨

### DOD-006 — Output Document IR와 Renderer

**상태:** `open`

Agent의 masked result를 Gateway가 검증된 Output Document IR로 만드는 문법과 Renderer/Fusion Sink가
새 파일을 생성하는 계약을 확정한다.

#### 이 결정이 필요한 이유

LLM이 DOCX/PDF bytes나 임의 markup을 직접 만들게 하면 active content, path, external reference와
marker 변형을 통제하기 어렵다. LLM에는 masked content와 제한된 구조만 허용하고, trusted local
renderer가 검증된 Output Document IR에서 새 파일을 생성해야 한다. 원본 파일을 수정하는 방식이 아니라
새 문서를 deterministic하게 만드는 흐름을 기본으로 한다.

#### 용어와 신뢰 경계

| 용어 | 의미 |
|---|---|
| Input CDIR | Parser가 입력 파일에서 추출한 정규화 구조. Gateway 검사 전에는 민감 평문을 포함할 수 있음 |
| Agent-safe IR | 모든 Agent-bound text가 마스킹되고 handle/marker로 치환된 구조 |
| Output Document IR | Agent 결과를 Gateway가 제한 schema로 검증·정규화한 출력용 중간 표현 |
| Marker | 마스킹된 원문 위치를 나타내는 문법적으로 제한된 token |
| Provenance | 출력 node/text가 입력, Agent 생성, template 또는 reveal 중 어디에서 왔는지 나타내는 정보 |
| Serializer | Output IR을 특정 파일 형식 bytes로 변환하는 deterministic component |
| Renderer/Fusion Sink | 승인된 marker만 local-only로 복원하고 파일을 생성·검증·publish하는 trusted process |
| Atomic publish | 완성·검증된 임시 출력물을 최종 경로에 한 번에 노출하는 동작 |

#### 기준 출력 흐름

```text
Agent/LLM의 masked result
  -> Secure Gateway: 허용 문법 parsing, schema·quota·marker 검증
  -> Output Document IR
  -> 사용자 local reveal 승인
  -> Renderer/Fusion Sink: 승인된 marker resolve
  -> 형식별 deterministic serializer
  -> 임시 출력 파일
  -> 재파싱/구조·marker·active-content 검증
  -> 사용자가 승인한 경로로 atomic publish
```

LLM은 filesystem path, raw file bytes, OOXML/PDF object, relationship, macro와 renderer option을 직접
지정할 수 없다. Filename과 output directory는 trusted UI 또는 정책이 결정하고, Agent가 제안한 이름은
sanitization 후에도 사용자 입력과 동일하게 신뢰하지 않는다.

#### Output IR 기준 후보

- 허용 node는 document, heading, paragraph, list, table, row, cell, inline text와 제한된 link 등 최소 집합으로
  시작한다.
- 모든 text는 plain Unicode string과 marker token sequence로 표현하며 raw HTML/XML/PDF instruction을
  허용하지 않는다.
- Node마다 stable ID, provenance, source reference(있는 경우)와 sensitivity state를 둔다.
- Marker는 분할·중첩·부분 수정할 수 없고 block/table cell/inline boundary를 넘지 못하게 한다.
- 형식별 serializer가 표현할 수 없는 layout은 조용히 손실시키지 않고 명시적 오류 또는 사용자 확인으로
  처리한다.
- 출력 형식은 입력 형식과 독립적으로 선택하되 초기에는 TXT/Markdown/CSV/TSV/JSON/DOCX/text PDF
  중 검증된 profile만 허용한다.

#### 실패와 안전한 기본 동작

- Unknown node/field, quota 초과, malformed marker, 승인되지 않은 handle과 provenance 단절은 render를 거부한다.
- 기존 파일 overwrite, symlink/reparse-point 탈출, path traversal과 network destination을 거부한다.
- Serializer crash 또는 재파싱 불일치 시 임시 파일을 publish하지 않는다.
- Local reveal 전의 IR과 로그에는 masked content만 남기며, 생성된 평문 파일은 Agent 경로로 되돌리지 않는다.

결정할 질문:

- 허용 node, field, depth, size와 provenance schema는 무엇인가?
- LLM text/tool result를 누가 어떤 deterministic grammar로 IR에 변환하는가?
- Marker/handle이 block, table cell과 inline boundary를 넘을 수 있는가?
- TXT/Markdown/CSV/TSV/JSON/DOCX/PDF별 serializer profile은 무엇인가?
- Unsupported layout, filename, overwrite와 output path를 어떻게 처리하는가?
- 생성 파일 재파싱 검증과 atomic publish 조건은 무엇인가?
- Output IR version upgrade 시 이전 session의 IR을 render할 수 있는가?
- 형식별 서식 손실을 오류, warning 또는 사용자 승인 중 무엇으로 처리하는가?

완료 조건:

- Versioned Output IR JSON schema와 예제가 정의됨
- Input IR과 Output IR의 신뢰·provenance 차이가 명시됨
- Renderer capability, filesystem sandbox와 format profile이 정의됨
- [`1-10. secure-file-egress.md`](1-10.%20secure-file-egress.md)에 반영됨

### DOD-007 — PII ambiguity와 사용자 확인

**상태:** `open`

지원 detector가 불확실한 입력을 만났을 때 사용자 확인 또는 전체 거부 중 무엇을 선택하는지 실행 가능한
정책으로 확정한다.

#### 이 결정이 필요한 이유

PII 검출은 checksum처럼 결정적인 규칙도 있지만 문맥과 locale에 따라 모호한 경우가 있다. False
negative는 민감정보를 LLM에 노출하고, false positive는 정상 작업을 막거나 과도하게 마스킹한다. 이름은
현재 제품 정책상 검출·마스킹 대상에서 제외하므로, detector가 임의로 범위를 넓혀서도 안 된다.

#### 용어

| 용어 | 의미 |
|---|---|
| PII kind | 주민등록번호, 전화번호, 계좌번호 등 정책이 구분하는 민감정보 유형 |
| Candidate | Detector가 PII일 가능성이 있다고 찾은 text span |
| Confidence | Candidate가 해당 PII kind일 가능성에 대한 detector 신호. 보안 보장은 아님 |
| Validation | 길이, checksum, prefix, 날짜와 context 같은 kind별 규칙 검사 |
| Ambiguity | 하나의 text가 여러 kind이거나 PII/비PII 여부를 정책만으로 확정할 수 없는 상태 |
| False negative/positive | PII를 놓침 / PII가 아닌 값을 PII로 판정함 |
| Trusted confirmation UI | 원문을 볼 수 있지만 Agent/LLM과 분리된 local 사용자 확인 화면 |
| Override | 사용자가 특정 candidate의 분류 또는 처리를 명시적으로 변경한 결정 |

#### 기준 판정 파이프라인

```text
CDIR text
  -> 정규화하되 원본 offset mapping 보존
  -> kind별 후보 탐지
  -> checksum/형식/context/locale 검증
  -> overlap 및 충돌 해결
  -> CONFIRMED | AMBIGUOUS | CLEAR | UNSUPPORTED
  -> CONFIRMED는 masking
  -> AMBIGUOUS는 trusted UI 확인 또는 전체 fail-closed
  -> UNSUPPORTED/coverage 불완전은 Agent 전달 금지
```

Confidence 숫자 하나로 허용 여부를 결정하지 않고 kind별 결정표를 사용한다. 예를 들어 checksum이 있는
식별자는 checksum과 context를 함께 사용하고, 전화번호처럼 locale 의존성이 큰 값은 session locale과
명시적 형식 규칙을 사용한다. 구체 threshold는 corpus로 검증한 뒤 확정한다.

#### 기준 사용자 확인 정책

- 확인 UI는 Gateway/Core의 trusted local surface이며 Agent가 text, 선택지 또는 결과를 조작하지 못한다.
- 사용자에게 필요한 최소 주변 문맥만 보여주고 목적, PII kind 후보와 처리 결과를 명확히 표시한다.
- Timeout, UI 종료와 응답 누락은 허용으로 간주하지 않고 fail-closed한다.
- Override는 기본적으로 object/session/span/detector-version에 결속하며 전역 학습 규칙으로 자동 승격하지
  않는다.
- Override audit에는 원문을 기록하지 않고 candidate digest, kind, decision, policy/detector version과
  사용자/장치 승인 evidence만 기록한다.
- 이름 제외 정책은 “이름을 안전하다고 판정했다”는 뜻이 아니라 제품이 의도적으로 masking하지 않는
  알려진 잔여 위험이다.

#### 충돌과 실패 기준 후보

- Span overlap은 더 구체적이고 검증 강도가 높은 kind를 우선하되 결정표에 없는 조합은 ambiguous다.
- 일부 segment만 불확실해도 그 segment가 Agent-bound이면 확인 전 전체 object 전달을 보류한다.
- 지원하지 않는 locale/script, offset 불일치, detector crash와 truncation은 clear로 취급하지 않는다.
- 사용자 확인 기능을 제공하지 않는 배포 모드에서는 ambiguous input을 자동 허용하지 않고 거부한다.

결정할 질문:

- 초기 지원 언어와 locale은 무엇인가?
- PII kind별 confidence와 checksum/context threshold는 무엇인가?
- 어떤 ambiguity를 trusted UI에 표시해 사용자가 확인할 수 있는가?
- 사용자 override는 session-bound인가, 저장되는가, audit 대상인가?
- Detector overlap과 충돌 우선순위는 무엇인가?
- 파일 전체 거부와 특정 segment 거부의 기준은 무엇인가?
- 이름 제외를 UI와 audit에서 어떻게 명시하고 향후 정책 변경 시 기존 object를 어떻게 재검사하는가?
- Detector/version 변경이 cached masking 결과와 handle에 어떤 영향을 주는가?

완료 조건:

- PII kind별 ambiguity decision table이 정의됨
- 사용자 확인 UI의 plaintext 위치와 Agent 비가시성이 정의됨
- 확인·거부·timeout·override test가 정의됨
- [`1-7. pii-content-policy.md`](1-7.%20pii-content-policy.md)에 반영됨

### DOD-008 — Hermes/OpenShell 강제 가능성

**상태:** `open`

Secure Gateway의 보안 주장을 Hermes와 현재 고정 OpenShell runtime에서 실제로 강제할 수 있는지
검증한다. 이는 제품 기능 개발이 아니라 아키텍처 가능성 spike다.

#### 이 결정이 필요한 이유

Secure Gateway가 정상 경로에서 masking하더라도 Hermes가 direct provider connection, 다른 input channel,
memory, tool 또는 filesystem을 통해 우회하면 “LLM 평문 0”을 주장할 수 없다. 문서상의 연결선이 아니라
고정한 Hermes/OpenShell version에서 실제로 ingress, inference egress와 local reveal 경계를 강제할 수
있는지 재현 가능한 실험으로 확인해야 한다.

#### 두 운영 모드의 차이

| 모드 | 보안 범위 | 허용 주장 |
|---|---|---|
| MCP tool-only | Agent가 선택적으로 privacy tool을 호출 | Tool에 전달된 값만 보호. Agent가 이미 본 prompt 평문까지 보호한다고 주장하지 않음 |
| Secure Gateway | 모든 사용자 입력·파일과 모든 provider-bound output을 Gateway가 선점 | 검증된 우회 차단 범위 안에서만 비신뢰 LLM에 민감 평문을 보내지 않는다고 주장 |

#### 검증할 신뢰 경계

```text
사용자/파일 -> Secure Gateway -> masked request -> Hermes -> 승인 inference route -> LLM
                                      |
                                      +-> MCP Bridge child -> Agent-safe tools

PC/Phone reveal -> local-only Fusion Sink/Renderer
                  (Hermes, MCP Bridge, provider network로 연결 금지)
```

Hermes는 OpenShell sandbox workload main process이고 MCP Bridge는 Hermes가 생성하는 child stdio process
후보다. 최종 부모·자식 관계는 DOD-003 manifest에서 확정한다.

#### Capability별 검증 방법

- **Ingress 선점:** TUI, webhook, attachment, memory replay와 system/internal prompt를 포함한 모든
  provider-bound content가 Gateway 정책을 통과하는지 sealed/negative test로 확인한다.
- **Provider egress 통제:** Hermes가 승인 proxy 이외의 DNS/IP/socket으로 직접 나갈 수 없고 credential을
  보유하지 않는지 확인한다.
- **Tool 통제:** MCP Bridge가 허용 schema와 handle만 받고 host-only/reveal IPC, key store, Vault와 원본
  filesystem에 접근할 수 없는지 확인한다.
- **Streaming/error 통제:** token stream, exception, trace, retry payload와 telemetry도 Gateway 이전에
  회수되거나 민감값을 포함하지 않음을 확인한다.
- **Persistence 통제:** Hermes memory, cache, transcript와 workspace에 unmasked 원문이 기록되지 않는지
  확인한다.
- **Reveal 격리:** local reveal path에 sandbox identity와 provider route가 연결될 수 없음을 OS 권한과
  network policy로 확인한다.

#### 판정 원칙

각 capability는 `PASS`, `FAIL`, `UNVALIDATED`, `NOT_APPLICABLE`과 evidence 경로를 가진다. 하나의 필수
capability라도 `FAIL` 또는 `UNVALIDATED`이면 해당 플랫폼/version에서 secure gateway mode와 “LLM 평문
0”을 지원 완료로 표시하지 않는다. 문서 설명이나 mock test만으로 `PASS`를 부여하지 않는다.

확인할 항목:

- Hermes direct input, TUI, webhook, memory와 fallback channel 차단
- Streaming/error/final output의 Gateway 이전 완전 회수
- Direct provider/network 접근 차단과 승인 inference route
- Hermes child MCP Bridge의 stdio lifecycle
- OpenShell connect/exec/sync/forward/service exposure 차단
- Sandbox identity, policy revision과 Core lease binding
- Key/Vault/host-only/reveal path 및 IPC 접근 거부
- Hermes/OpenShell upgrade마다 어떤 conformance suite를 다시 실행하는가?
- 완전 강제가 불가능하면 adapter 변경, upstream 변경 또는 secure mode 비지원 중 무엇을 선택하는가?

완료 조건:

- Capability별 pass/fail과 재현 명령이 기록됨
- 불가능한 capability가 있으면 secure mode 지원을 주장하지 않음
- 필요한 OpenShell 변경과 FHE-Privacy 소유 변경이 분리됨
- [`secure-gateway-wrapper-investigation.md`](secure-gateway-wrapper-investigation.md)와 adapter 계약에 반영됨

## P1 — P0 이후 확정 가능

### DOD-009 — Protocol, retry와 idempotency

**상태:** `open`

Session/envelope/handle/tool/reveal/render 요청의 version, error code, retry, cancellation, timeout과
idempotency key를 정의한다. 중복 요청이 ciphertext, handle, partial share 또는 output file을 중복 생성하지
않도록 한다.

#### 이 결정이 필요한 이유

Process와 장치 사이 요청은 timeout 뒤 실제 성공 여부를 알 수 없을 수 있다. Client가 같은 요청을 다시
보냈을 때 새 object, 새 reveal 승인 또는 출력 파일이 중복 생성되면 보안 상태와 사용자 의도가 달라진다.
모든 protocol이 같은 version/error/retry 의미를 사용해야 crash와 network 단절에서도 fail-closed할 수 있다.

#### 용어

| 용어 | 의미 |
|---|---|
| Protocol version | Message schema와 의미의 호환 단위 |
| Request ID | 한 번의 전송/처리를 추적하는 고유 ID |
| Idempotency key | 같은 논리 동작의 재시도를 식별하여 결과를 한 번만 만들게 하는 key |
| Correlation ID | 여러 process의 관련 event를 원문 없이 연결하는 추적 ID |
| Retryable error | 같은 권한과 idempotency key로 제한된 재시도가 안전한 오류 |
| Terminal error | 정책 거부, 만료, schema mismatch처럼 자동 재시도하면 안 되는 오류 |
| Cancellation | 요청자의 중단 의사. 이미 commit/reveal된 결과를 자동으로 되돌린다는 뜻은 아님 |

#### 공통 message envelope 기준 후보

모든 IPC/API message는 `protocol_version`, `message_type`, `request_id`, `idempotency_key`(필요 시),
`session_id`, `object_id`(필요 시), `caller_identity`, `policy_version`, `deadline`, `body`와 인증된 binding을
가진다. Secret/plaintext를 ID, error, metric과 log field에 넣지 않는다.

#### 동작별 idempotency 기준

| 동작 | 같은 key 재시도 결과 |
|---|---|
| Session 생성 | 같은 session 또는 최종 상태 반환 |
| 파일 ingest/commit | 같은 object/handle 반환; 새 DEK/object를 만들지 않음 |
| Tool operation | operation 특성에 따라 cached result 또는 명시적 non-retryable |
| Reveal 요청 | 같은 승인 의도와 destination일 때만 기존 상태 반환; 새 승인을 암묵 생성하지 않음 |
| Partial/share 제출 | 중복은 한 번으로 계산; 다른 payload면 충돌 거부 |
| Render/publish | 같은 output artifact 반환; 다른 path/content면 충돌 거부 |
| 삭제 | 이미 삭제됐어도 성공 의미를 유지하되 tombstone/policy를 검증 |

#### Error와 retry 원칙

- Error는 안정된 machine code, 안전한 사용자 메시지, retry 가능 여부와 correlation ID를 가지며 내부
  exception, path, plaintext와 cryptographic material을 노출하지 않는다.
- Policy denial, malformed message/share, binding mismatch, replay, expiry와 unsupported version은 자동
  retry하지 않는다.
- Deadline 이후 완료될 수 있는 operation은 상태 조회 protocol을 제공하며 무조건 재실행하지 않는다.
- Cancellation 뒤 새 handle/reveal/output을 공개하지 않으며, 이미 commit된 결과는 명시적 보상 동작으로
  처리한다.
- Idempotency record의 TTL이 operation 결과와 retention보다 짧아서 중복이 재생성되지 않게 한다.

#### 결정할 질문

- Protocol별 version negotiation과 minimum supported version은 무엇인가?
- Idempotency scope는 caller/session/object 중 어디까지이며 key는 누가 생성하는가?
- 각 operation의 commit point와 `UNKNOWN_OUTCOME` 조회 방식은 무엇인가?
- Error taxonomy, retry budget, backoff, deadline과 cancellation 전파 규칙은 무엇인가?
- Partial/share와 reveal approval의 replay cache를 어디에 얼마나 유지하는가?

#### 완료 조건

- 공통 message envelope와 protocol별 schema가 versioned artifact로 정의됨
- Operation별 idempotency/commit/retry/cancel matrix가 정의됨
- Duplicate, delayed, reordered, lost-response와 crash-after-commit test가 정의됨
- Error/log에 plaintext·key·share가 없음을 검증하는 negative test가 정의됨

### DOD-010 — 운영 수치와 audit

**상태:** `open`

입력 크기, page/cell/depth, timeout, operation budget, handle TTL, quarantine/retention, log/audit event와
redaction schema를 확정한다.

#### 이 결정이 필요한 이유

“제한한다”, “곧 삭제한다”, “감사한다”만으로는 구현과 검증이 불가능하다. Resource exhaustion,
decompression bomb, 무기한 handle과 과도한 개인정보 log를 막으려면 플랫폼/profile별 수치와 관측
event를 정해야 한다. 수치는 추측으로 고정하지 않고 corpus와 부하 시험 근거를 남긴다.

#### 운영 설정 범주

| 범주 | 결정할 예 |
|---|---|
| Ingress quota | 파일/요청 크기, session 총량, 동시 upload 수 |
| Parser quota | wall/CPU time, memory, decompressed bytes, page/part/cell/node/depth 수 |
| Crypto quota | object/chunk 크기, FHE operation budget, 동시 reveal 수 |
| Protocol timeout | Gateway, parser, tool, PC/Phone approval, render와 publish deadline |
| Lifetime | Session, hot DEK, handle, lease, idempotency record, quarantine와 tombstone TTL |
| Storage retention | encrypted original, Vault record, output, backup/snapshot과 audit retention |
| Rate limit | caller/device/session별 ingest, reveal, 실패와 approval 시도 |

#### Log, metric과 audit 구분

- **Log:** 장애 진단용 event. 원문, marker 원값, DEK/share, ciphertext 전체, 원본 filename/path를 기록하지 않는다.
- **Metric:** count, latency, size bucket, error code 같은 집계값. Object/사용자를 고카디널리티 label로 넣지 않는다.
- **Security audit:** 누가 어떤 정책/version으로 object lifecycle, device approval, reveal, override, deletion을
  요청·승인·거부했는지 append-only로 기록한다. 원문 대신 opaque ID와 digest를 사용한다.

공통 event 후보는 timestamp, event version, component/process identity, action, result/error code,
correlation/session/object의 opaque ID, policy/profile/key-set version, destination class와 evidence digest다.
Audit integrity에는 chained MAC/signature, 접근 통제, rotation과 clock/sequence rollback 탐지가 필요하다.

#### 안전한 기본값 원칙

- Profile에 수치가 없거나 파싱할 수 없으면 무제한으로 동작하지 않고 시작 또는 요청을 거부한다.
- Limit 초과는 partial/truncated content를 Agent에 보내지 않고 전체 operation을 실패시킨다.
- Debug/trace mode도 secret redaction을 해제하지 않는다.
- Retention 만료는 handle revoke, active lease 종료, 저장소 삭제와 audit evidence 순서를 정의한다.
- Production 수치는 지원 플랫폼별 부하·negative corpus evidence가 있어야 `validated`로 표시한다.

#### 결정할 질문

- 각 format/platform의 hard limit과 soft warning 수치는 얼마인가?
- Hot DEK, session, handle, quarantine, audit와 backup의 TTL/retention은 얼마인가?
- Audit 열람·export·삭제 권한과 개인정보 최소화 기준은 무엇인가?
- Clock rollback, disk full, audit sink 장애 시 operation을 허용할 것인가?
- Telemetry를 외부로 보낼 수 있는가? 가능하다면 어떤 aggregate field만 허용하는가?

#### 완료 조건

- Versioned quota/timeout/retention profile과 산정 evidence가 존재함
- Event catalog, redaction schema와 process별 log/audit 허용 필드가 정의됨
- Limit boundary, log injection, disk full, audit failure와 secret scanning test가 정의됨
- 운영자 문서에 탐지·대응·삭제 절차와 잔여 위험이 반영됨

### DOD-011 — 장치 수명주기와 recovery

**상태:** `open`

Enrollment, rotation, revocation, lost device, key-set migration과 2-of-3 recovery 도입 여부를 확정한다.
초기 버전에서 recovery를 제공하지 않으면 장치 분실 시 영구 복구 불가를 제품 계약에 명시한다.

#### 이 결정이 필요한 이유

2-of-2는 한 장치 침해만으로 복호하지 못하게 하지만 한 장치 분실만으로도 모든 기존 object를 복구하지
못할 수 있다. 편리한 single-device recovery는 보안 불변식을 깨고, 안전한 rotation도 기존 두 장치가
동시에 유효할 때 수행하지 않으면 attacker가 새 key set에 참여할 수 있다.

#### 용어

| 용어 | 의미 |
|---|---|
| Enrollment | PC와 Phone identity/key를 신뢰 관계에 처음 등록하는 절차 |
| Key set | 함께 사용되는 PC/Phone key와 version의 묶음. `key_set_id`로 식별 |
| Rotation | 유효 key를 새 key로 교체하고 object envelope를 이전하는 절차 |
| Revocation | 특정 장치/key가 앞으로 승인·복호에 참여하지 못하게 하는 조치 |
| Re-enveloping | 데이터 ciphertext를 다시 암호화하지 않고 DEK 보호 envelope만 새 key set으로 교체 |
| Recovery | 장치 분실 뒤 기존 object 접근을 복구하는 절차 |
| 2-of-3 | 세 authority 중 두 곳 승인이 필요한 정책. 별도 recovery authority가 생김 |
| Forward/backward access | 새 key가 과거 object를 / 폐기된 key가 미래 object를 복호할 수 있는지에 대한 성질 |

#### 기준 수명주기

**Enrollment:** 두 장치의 독립 identity 확인, physical/user confirmation, 공개키 교환, key possession 증명,
key-set 생성과 trusted UI fingerprint 확인을 요구한다. QR/activation code 같은 bootstrap 값은 짧은 TTL과
일회성을 가져야 한다.

**정상 rotation:** 기존 PC와 Phone이 새 key set을 함께 승인한다. Object별 DEK를 승인된 Fusion Sink에서
복구한 뒤 새 share/envelope로 re-envelope하며, 완료 전에는 old/new 상태를 transaction으로 추적한다.
모든 object 이전과 검증이 끝난 뒤 old key set을 폐기한다.

**의심·도난 revocation:** 새 reveal을 즉시 거부하고 device/key set을 revoked 상태로 만든다. 2-of-2에서
남은 한 장치만으로 기존 DEK를 이전할 수 없으므로 사전 recovery 설계가 없다면 기존 데이터는 복구
불가능하다.

#### Recovery 선택지

| 선택지 | 보안·가용성 영향 |
|---|---|
| Recovery 없음 | 가장 단순하고 2-of-2 불변식이 명확하지만 PC 또는 Phone 분실 시 영구 복구 불가 |
| 2-of-3 recovery authority | 한 장치 분실에도 복구 가능하지만 세 번째 고가치 share의 보관·인증·남용 위험이 추가됨 |
| Offline recovery kit | 사용자가 보관할 수 있으나 복사·도난·분실과 지원 절차가 새로운 공격면이 됨 |
| Vendor/cloud escrow | 가용성은 높지만 local-only 및 vendor 단독 복구 불가 요구와 충돌 가능성이 큼 |

Recovery를 제공한다면 평상시 2-of-2 보안을 낮추지 않고, 최소 두 독립 authority와 명시적 사용자 확인,
지연·알림·감사 및 기존 key revocation을 요구해야 한다. 단일 password, email reset, vendor master key와
PC-only/Phone-only fallback은 허용하지 않는다.

#### 결정할 질문

- 초기 release에 recovery를 제공하는가, 아니면 영구 복구 불가를 명시하는가?
- Enrollment에서 장치와 사용자 identity를 어떻게 확인하고 MITM을 막는가?
- Planned rotation, compromise rotation과 algorithm migration 절차는 각각 무엇인가?
- Re-enveloping 중 crash/offline/일부 object 실패를 어떻게 복구하는가?
- Revocation 상태와 key-set rollback을 누가 authoritative하게 저장·검증하는가?

#### 완료 조건

- Enrollment/rotation/revocation/loss/recovery state machine과 사용자 계약이 정의됨
- Key-set version, object migration과 old-key destruction evidence가 정의됨
- Stolen device, malicious enrollment, rollback, partial migration과 recovery abuse test가 정의됨
- Recovery 없음 선택 시 장치 분실의 영구 데이터 손실이 UI·문서·onboarding에 명시됨

### DOD-012 — 플랫폼·배포·migration

**상태:** `open`

Linux/macOS/Windows WSL, local/Kubernetes 지원 범위, IPC 차이, dependency pinning, config/storage schema
upgrade, rollback과 compatibility matrix를 확정한다.

#### 이 결정이 필요한 이유

OS마다 key store, process sandbox, UDS/named pipe, memory locking, filesystem atomicity와 mobile 연동이
다르다. 한 플랫폼에서 통과한 보안 주장을 다른 플랫폼에 자동 적용할 수 없다. 또한 package, native
runtime, protocol과 저장 schema가 함께 변경되므로 partial upgrade와 rollback이 ciphertext 또는 key를
읽지 못하게 만들 수 있다.

#### 현재 플랫폼 기준선

| 플랫폼 | 현재 위치 | 설계상 주의점 |
|---|---|---|
| Linux x86-64 | OpenFHE build target | UDS, process identity, sandbox/key store와 배포 package 검증 필요 |
| macOS Apple Silicon | bootstrap/checksum 가능, `unvalidated` | sandbox, Keychain, IPC와 OpenShell compatibility evidence 필요 |
| Windows x86-64 + Ubuntu WSL 2 | 지원 예정 경로; native `.exe` 아님 | Windows host·WSL trust boundary, IPC/filesystem/key storage와 OpenShell sealed test 필요 |
| Kubernetes | 배포 후보일 뿐 미확정 | Local-only reveal, phone authority, pod reschedule, secret/storage/network policy 재설계 필요 |

지원 여부는 `supported`, `experimental`, `unvalidated`, `unsupported`로 구분하고 기능별 evidence를
연결한다. “build 성공”은 parser sandbox, secure gateway 강제와 reveal까지 지원한다는 뜻이 아니다.

#### 배포 구성요소와 version 축

- Python package와 CLI/service entry point
- OpenFHE wheel/backend와 OpenShell native runtime
- Hermes/OpenShell adapter와 MCP protocol
- Parser library와 format coverage profile
- Crypto algorithm/envelope/key-set version
- IPC/wire protocol, policy/config와 저장 schema
- PC/Phone app protocol과 minimum supported version

`versions.lock`과 artifact checksum/signature를 사용하고, 설치 시 platform/architecture/backend smoke test와
호환성 검사를 수행한다. 제품 package와 `init.sh`가 아직 재구축 전이라는 현재 상태를 지원 완료로
오인하지 않는다.

#### Upgrade와 migration 기준

1. Upgrade 전 binary/config/schema/protocol compatibility와 필요한 disk space를 preflight한다.
2. 저장 schema와 envelope migration은 versioned journal과 resume 가능한 idempotent step을 사용한다.
3. Old reader가 이해하지 못하는 irreversible write 전에 backup 정책과 rollback 가능 경계를 명시한다.
4. Crypto migration은 ciphertext 재암호화와 DEK re-enveloping을 구분하고 PC/Phone 참여 요구를 보존한다.
5. Mixed-version PC/Phone/Gateway는 명시된 compatibility window 밖에서 fail-closed한다.
6. Downgrade가 새 policy, revocation, nonce 또는 anti-rollback 상태를 잃으면 거부한다.
7. Upgrade 뒤 negative/conformance suite가 실패하면 service를 지원 상태로 표시하지 않는다.

#### 배포 형태별 신뢰 경계

- **단일 사용자 local:** 기본 목표다. Host-only IPC, OS identity, local key store와 loopback/network 차단을
  검증한다.
- **WSL 2:** Windows host app/Phone bridge와 Linux workload 사이 어느 쪽을 trusted host로 보는지, key와
  plaintext가 `\\wsl$`/shared filesystem을 통과하는지 명시한다.
- **Kubernetes:** 지원하려면 local-only의 의미, node trust, persistent volume encryption, pod identity,
  phone route와 Fusion Sink 위치를 새 threat model로 먼저 결정한다. 초기 비범위로 둘 수 있다.

#### 결정할 질문

- 첫 release의 정확한 OS/architecture와 secure-mode 지원 matrix는 무엇인가?
- 플랫폼별 key store, IPC, sandbox, memory/crash-dump 통제 backend는 무엇인가?
- Local package/service install, update 권한과 artifact provenance를 어떻게 검증하는가?
- Protocol/config/storage/crypto별 호환성 window와 migration 순서는 무엇인가?
- Upgrade 실패, downgrade, interrupted migration과 unsupported platform의 안전한 동작은 무엇인가?
- Kubernetes를 초기 비범위로 확정할 것인가, 별도 threat model을 작성할 것인가?

#### 완료 조건

- 기능별 platform/architecture/backend compatibility matrix와 evidence 링크가 존재함
- 설치·upgrade·rollback·migration state machine과 operator runbook이 정의됨
- Tampered artifact, partial upgrade, mixed version, migration crash와 downgrade test가 정의됨
- `unvalidated` 플랫폼에서 지원·보안 완료 주장을 하지 않도록 문서와 release gate가 연결됨

## 문서 정합성 정리 항목

다음 항목은 해당 DOD를 닫을 때 함께 수정한다.

- `1-1`의 “handle 상세 계약은 후속 설계” 표현을 이미 존재하는 `1-4` 참조로 교체
- `1-5`와 `reveal-device-policy.md`, `threshold-fhe-reveal.md`의 현재 2-of-2 모델 정합성 재검토
- `secure-gateway-wrapper-investigation.md`의 attachment 전체 비지원 표현을 허용 file profile 기준으로 수정
- `feature_list.json`의 파일 ingress/egress 항목을 검증 단위별로 세분화
- Draw.io의 그룹형 상자와 실제 process manifest 관계를 명시

## 결정 기록 형식

각 항목을 닫을 때 다음 형식을 사용한다.

```text
Decision ID:
Status: decided | deferred
Date:
Decision:
Alternatives considered:
Security impact:
Availability/UX impact:
Affected documents:
Required negative tests:
Remaining risks:
```

## 다음 시작점

다음 설계 세션은 **DOD-001 — Exact secret/file DEK의 2-of-2 threshold envelope primitive**만 검토한다.
선택지 비교, backend 가능성, complete secret 부재와 one-share denial을 증명할 수 있는 protocol부터
정리한다.
