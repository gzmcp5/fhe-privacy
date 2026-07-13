# Threshold FHE Reveal 설계 노트

## 쉽게 말하면

PC와 스마트폰이 금고 열쇠의 역할을 나눠 가진다. 어느 한쪽도 혼자서는 결과를 열 수 없다. 결과를
볼 때 두 장치가 각각 불완전한 복호 결과를 만들고, 승인된 PC 또는 스마트폰에서 둘을 합쳐 최종
평문을 만든다. 완성된 비밀키 파일은 어느 장치에도 만들지 않는다.

용어 설명: [`glossary.md`](glossary.md)

> 2026-07-09 초안, 2026-07-13 보안 아키텍처 정합성 갱신. 이 문서는 PC와 스마트폰이 함께 참여해야 고위험 reveal이 가능한
> `Threshold FHE Reveal`의 개념, 키 구조, 동작 흐름, 구현 고려사항을 정리한다.

## 1. 목적

FHE-Privacy의 기본 reveal 모델은 PC와 스마트폰이 모두 참여하는 `2-of-2`다. 암호문과 Vault가
PC에 있어도 PC는 `sk_pc`만 보유하고 스마트폰의 `sk_phone` 없이 결과를 열 수 없다. TPM과
Secure Enclave 같은 장치는 각 share의 저장 중 보호를 강화하지만 필수 신뢰 기반은 아니다.

`Threshold FHE Reveal`은 모든 FHE reveal에서 다음 성질을 강제하는 기본 모델이다.

```text
PC 혼자 reveal 불가
스마트폰 혼자 reveal 불가
PC와 스마트폰이 모두 partial decryption에 참여해야 reveal 가능
고보증 모드에서는 최종 plaintext fusion과 표시를 스마트폰에서만 수행
```

이 모델은 스마트폰의 wrapping key를 PC로 보내는 방식이 아니다. 스마트폰은 자기
secret share 또는 phone-backed key share를 보유하고, reveal 요청마다 정책 검사를 통과한
경우에만 partial decryption share를 만든다.

## 2. 용어 구분

### 2.1 Multiparty FHE와 Threshold FHE

두 용어는 겹치지만 같은 말은 아니다.

```text
Multiparty FHE:
  여러 party가 참여하는 FHE 프로토콜 전체 범주
  threshold key generation / decryption
  collective evaluation key generation
  interactive bootstrapping
  proxy re-encryption 등을 포함할 수 있음

Threshold FHE:
  정해진 수 이상의 key share가 참여해야 복호화 가능한 구조
  reveal 권한을 분산하는 보안 성질에 초점
```

이 프로젝트의 설계 용어는 `Threshold FHE Reveal`이 적합하다. 구현 API는 OpenFHE의
`MultipartyKeyGen`, `MultipartyDecryptLead`, `MultipartyDecryptMain`,
`MultipartyDecryptFusion`처럼 `Multiparty` 이름을 쓸 수 있다.

### 2.2 t-of-n threshold

`threshold`는 복호화에 필요한 최소 참여 수를 뜻한다.

```text
2-of-2:
  PC share와 smartphone share가 모두 있어야 reveal 가능

2-of-3:
  PC, smartphone, recovery device 중 2개 이상이 있으면 reveal 가능

3-of-5:
  5개 share 중 3개 이상이 있어야 reveal 가능
```

FHE-Privacy의 기본 FHE key/reveal 모델은 PC와 스마트폰의 `2-of-2`다. 위험도는 threshold 적용
여부가 아니라 fusion 목적지(PC 또는 phone)를 결정한다. 복구성과 가용성을 높이려면 나중에
recovery device를 추가한 `2-of-3`을 검토할 수 있다.

## 3. 단일키 FHE와 Threshold FHE의 차이

### 3.1 단일키 FHE 비교 모델

단일키 모델은 비교와 migration 금지 판단을 위한 설명일 뿐 production 지원 모드가 아니다.
하나의 Reveal Authority가 완성된 secret key를 가지므로 PC·스마트폰 분리 보관 요구를 만족하지 않는다.

```text
KeyGen:
  sk -> pk
  sk -> eval keys

Encrypt:
  plaintext -> Encrypt(pk) -> ciphertext

Evaluate:
  ciphertext + eval keys -> result ciphertext

Decrypt:
  result ciphertext + sk -> plaintext
```

비밀키 하나가 복호화 권한 전체를 가진다. 공개 번들에는 `pk`와 relin/rotation 같은
evaluation key가 들어가고, secret bundle에는 `sk`가 들어간다.

FHE-Privacy는 이 secret bundle을 생성하거나 2-of-2 장애 시 fallback으로 사용하지 않는다.

### 3.2 Threshold FHE

Threshold FHE에서는 하나의 완성된 secret key를 그대로 두 조각으로 자르는 것이 아니라,
처음부터 여러 party가 공동 secret에 대응하는 공개키와 연산키를 만든다.

```text
Private:
  sk_pc
  sk_phone

Public:
  pk_joint
  eval_keys_joint

Encrypt:
  plaintext -> Encrypt(pk_joint) -> ciphertext

Evaluate:
  ciphertext + eval_keys_joint -> result ciphertext

Decrypt:
  PC: result ciphertext + sk_pc -> partial decrypt share
  Phone: result ciphertext + sk_phone -> partial decrypt share
  Fusion: partial shares -> plaintext
```

핵심은 `pk_joint`로 암호화된 ciphertext가 어느 한쪽 share만으로는 복호화되지 않는다는
점이다.

## 4. 키 구조

### 4.1 Secret shares

```text
sk_pc:
  PC가 보유하는 secret share
  TPM-backed wrapping key로 저장 중 보호 가능
  단독으로 plaintext 복원 불가

sk_phone:
  스마트폰이 보유하는 secret share
  Secure Enclave / Android Keystore / StrongBox wrapping key로 저장 중 보호 가능
  단독으로 plaintext 복원 불가
```

`sk_phone`을 PC로 보내지 않는다. PC가 스마트폰에 reveal 요청을 보내면 스마트폰은
정책 검사와 사용자 승인을 거쳐 자기 share로 partial decryption만 수행한다.

각 share는 scheme과 parameter set에 종속된다. CKKS share가 BFV/BGV 또는 Boolean FHE ciphertext를
복호화할 수 있다고 가정하지 않는다. 지원 scheme마다 joint keygen, evaluation-key generation,
partial decrypt와 fusion을 독립적으로 검증한다.

### 4.2 Joint public key

최종 암호화에 쓰는 공개키는 개념적으로 하나다.

```text
pk_joint:
  sk_pc + sk_phone 공동 secret에 대응하는 공개키
  profile/vault 암호화에 사용
  public compute plane에 배포 가능
```

OpenFHE 예제 흐름은 첫 party가 `KeyGen()`으로 첫 key pair를 만들고, 다음 party가
이전 public key를 입력으로 `MultipartyKeyGen(previous_public_key)`을 수행해 joint public
key를 확장한다.

### 4.3 Joint evaluation keys

연산키도 단일 secret key용 key를 그대로 쓸 수 없다. 공동 secret에 맞는 collective
evaluation key bundle이 필요하다.

```text
eval_keys_joint:
  eval multiplication / relinearization key
  rotation / Galois keys
  eval sum keys
  bootstrapping keys, 필요 시
```

각 party가 자기 secret share로 partial evaluation key를 만들고, 이를 결합해
`eval_keys_joint`를 만든다. 생성 후 연산키는 public compute plane에서 동형 연산에
사용할 수 있지만, key tag와 배포 범위는 최소화해야 한다.

## 5. 동작 흐름

### 5.1 Setup

```text
1. PC와 스마트폰 페어링
2. FHE 파라미터 합의
3. PC secret share 생성
4. 스마트폰 secret share 생성
5. pk_joint 생성
6. eval_keys_joint 생성
7. public bundle 저장/배포
8. 각 secret share를 각 장치의 hardware-backed wrapping key로 저장
```

이 단계에서 만들어지는 public bundle은 현재 단일키 public bundle과 비슷한 역할을 하지만,
내용은 `pk_joint`와 `eval_keys_joint` 기준이어야 한다.

### 5.2 Encryption

```text
사용자 민감값
  -> Secure Gateway / PII mask
  -> Encrypt(pk_joint)
  -> ciphertext / vault entry
```

중요한 차이는 기존 `pk`가 아니라 `pk_joint`로 암호화한다는 점이다. 단일키 `pk`로 만든
기존 ciphertext를 그대로 threshold 복호화 대상으로 바꿀 수는 없다. 기존 데이터를 옮기려면
마이그레이션이나 re-encryption 절차가 필요하다.

### 5.3 Public compute

```text
ciphertext
  -> public compute plane
  -> eval_keys_joint로 homomorphic add/mul/rotate/sum
  -> result ciphertext
```

public compute plane에는 plaintext와 secret share가 없어야 한다. 공개키와 연산키만으로
동형 연산을 수행한다.

### 5.4 High-risk reveal

고위험 reveal은 fusion 위치가 보안 수준을 결정한다.

```text
PC
  -> RevealRequest 생성
  -> risk policy 검사
  -> result ciphertext를 스마트폰에 전송
  -> sk_pc로 partial decrypt share 생성
  -> PC partial share를 스마트폰에 전송

Smartphone
  -> 요청 내용 표시
  -> 사용자 인증 / 승인
  -> sk_phone으로 partial decrypt share 생성
  -> PC partial share + phone partial share fusion
  -> plaintext를 스마트폰 화면에 표시
  -> PC에는 displayed_on_phone 같은 비민감 상태만 반환
```

고보증 모드에서는 PC가 최종 plaintext를 받지 않는다. PC로 plaintext를 반환하면 PC
compromise에 다시 노출된다.

## 6. Fusion 위치별 보안 성질

### 6.1 PC fusion

```text
PC partial share + phone partial share -> PC에서 fusion -> PC plaintext
```

장점:

- 기존 PC UX와 연결하기 쉽다.
- PC 화면 출력, 클립보드, 파일 저장 같은 동작 구현이 간단하다.

한계:

- 승인된 reveal 순간 PC가 plaintext를 본다.
- PC compromise를 강하게 완화하지 못한다.

### 6.2 Phone fusion

```text
PC partial share -> smartphone
Phone partial share -> smartphone
smartphone fusion -> phone display
```

장점:

- PC 혼자 decrypt할 수 없다.
- 고위험 plaintext를 PC로 보내지 않을 수 있다.
- 기존 phone-backed wrapping key 모델보다 FHE secret 자체를 더 잘 분산한다.

한계:

- 스마트폰 앱에서 OpenFHE decrypt/fusion을 실행할 수 있어야 한다.
- 스마트폰 성능, 배터리, native library packaging 부담이 생긴다.
- PC가 보낸 ciphertext와 partial share의 무결성 검증이 필요하다.

FHE-Privacy의 고보증 reveal에는 `Phone fusion + phone display only`가 가장 맞다.

## 7. 이론적 직관

CKKS/BFV/BGV 계열 FHE는 보통 polynomial ring 위의 RLWE 기반 암호를 사용한다. 단일키
모델에서는 secret polynomial `s` 하나가 있고, 공개키와 evaluation key는 이 `s`에 대응한다.

Threshold 구조에서는 secret이 여러 share로 분산된다.

```text
single-key:
  s

2-party threshold:
  s = s_pc + s_phone  (개념적 표현)
```

실제 라이브러리 구현은 scheme별 noise, modulus switching, key switching, RNS 표현을
다루므로 단순 덧셈만으로 설명할 수는 없다. 그래도 보안 직관은 명확하다.

```text
pk_joint:
  aggregate secret에 대응하는 공개키

partial decryption:
  각 share가 ciphertext 복호화 과정의 자기 몫만 계산

fusion:
  충분한 partial shares가 모였을 때만 plaintext 복원
```

이것은 "A 비밀키로 1차 복호화하고 B 비밀키로 2차 복호화한다"는 구조가 아니다. 각 party는
같은 ciphertext에 대해 partial share를 만들고, 그 share들이 합쳐져 최종 plaintext가 된다.

## 8. OpenFHE 기준 구현 메모

OpenFHE 공식 문서는 BGV, BFV, CKKS에 대한 Threshold FHE와 CKKS threshold interactive
bootstrapping, proxy re-encryption을 multiparty extension으로 설명한다. 예제 목록에는
`threshold-fhe.cpp`가 BGVrns, BFVrns, CKKSrns threshold FHE 예제를 제공한다고 되어 있다.

과거 `openfhe-python==1.5.1.0` 바인딩 조사에서는 `CryptoContext`에 다음 multiparty API가
노출되는 것을 확인했다. 구현을 시작할 때 현재 wheel에서 다시 검증해야 한다.

```text
MultipartyKeyGen
MultipartyDecryptLead
MultipartyDecryptMain
MultipartyDecryptFusion
MultiKeySwitchGen
MultiAddEvalKeys
MultiMultEvalKey
MultiAddEvalMultKeys
MultiEvalSumKeyGen
MultiAddEvalSumKeys
MultiEvalAtIndexKeyGen
MultiAddEvalAutomorphismKeys
MultiAddPubKeys
```

따라서 Python에서 최소 spike 후보가 된다. 현재 구현과 bundle 포맷은 없으므로 threshold public
material과 secret share bundle을 처음부터 별도 version/kind로 설계한다.

## 9. FHE-Privacy 적용안

### 9.1 신규 개념 객체

```text
ThresholdFHEClient
  setup_lead_party()
  setup_join_party()
  export_joint_public_bundle()
  export_secret_share_bundle()
  partial_decrypt_lead()
  partial_decrypt_main()
  fuse_partials()

ThresholdRevealAuthority
  create_reveal_request()
  authorize_on_phone()
  produce_phone_partial()
  fuse_on_phone()
  return_display_status()

ThresholdRevealPolicy
  require_threshold_reveal
  phone_fusion_only
  allow_pc_fusion
  deny
```

### 9.2 Bundle 분리

```text
threshold public bundle:
  kind: threshold-public
  pk_joint
  eval_keys_joint
  crypto context
  participant policy
  key generation transcript hash

PC secret share bundle:
  kind: threshold-share
  participant: pc
  sk_pc encrypted by TPM-backed wrapping key

Phone secret share bundle:
  kind: threshold-share
  participant: phone
  sk_phone encrypted by phone-backed wrapping key
```

### 9.3 Reveal request 필드

```text
RevealRequest
  request id
  ciphertext handle
  marker id
  data kind
  destination
  purpose
  requester
  session id
  risk score
  policy decision
  transcript hash
```

`request id`, `ciphertext handle`, `destination`, `policy decision`은 partial decryption
결과와 함께 서명하거나 MAC으로 묶어야 한다. 그렇지 않으면 승인된 partial share가 다른
요청에 재사용될 수 있다.

## 10. 보안 주의사항

### 10.1 Decryption oracle 제한

Threshold reveal도 결국 복호화 oracle을 만든다. 공격자가 많은 ciphertext에 대해 partial
decryption과 fusion 결과를 얻을 수 있으면 CKKS 파라미터와 구현에 따라 위험해질 수 있다.

정책 계층에서 다음 제한이 필요하다.

- reveal 요청 rate limit
- request category와 destination binding
- replay 방지 nonce
- batch approval 범위 제한
- phone display only 기본값
- audit log
- abnormal request deny

### 10.2 CKKS approximate 특성

CKKS는 approximate arithmetic이므로 명시적 오차를 허용하는 numeric domain에만 사용한다.
Threshold key model은 CKKS에만 한정되지 않는다. Exact integer 연산은 검증된 BFV/BGV context,
exact predicate는 검증된 Boolean FHE context를 사용한다. Scheme마다 별도 2-of-2 key set을 사용하며
modulus, overflow, encoding, bootstrapping과 mobile partial-decrypt 지원을 검증한다.

전화번호, 주민등록번호, credential처럼 계산하지 않는 exact secret은 FHE 슬롯에 저장하지 않는다.
Record별 AEAD DEK와 2-of-2 threshold envelope를 사용한다. 이름은 현재 제품 정책상 탐지·masking
대상에서 제외한다. 주민등록번호는 trusted ingress에서
형식과 checksum을 검증하고, 생년월일 같은 파생 속성이 필요하면 원본과 분리된 typed value로 만든다.

### 10.3 Exact secret threshold envelope

AEAD 자체는 threshold FHE가 아니다. Gateway는 record별 random DEK로 exact secret을 AEAD 암호화하고,
DEK를 PC와 스마트폰 모두가 참여해야 unwrap 가능한 threshold envelope로 보호한다. 단일 AEAD master
key, PC-only unwrap key 또는 완성 key backup은 허용하지 않는다. Envelope primitive, enrollment,
rotation과 phone-fusion protocol은 별도 cryptographic spike에서 검증한다.

### 10.4 스마트폰 TEE 한계

Secure Enclave/StrongBox가 OpenFHE 복호화 전체를 보안 영역 안에서 실행해주는 것으로
가정하면 안 된다. 현실적인 구현에서는 스마트폰 앱 프로세스 메모리에 secret share 또는
partial decrypt 과정의 민감 material이 올라올 수 있다. 하드웨어 보안 기능은 주로 저장 중
보호, 사용 조건, 사용자 인증, attestation에 쓰인다.

### 10.5 가용성

`2-of-2`는 스마트폰 분실/고장 시 reveal이 불가능하다. 운영 모델에는 recovery code,
recovery device, emergency rotation, vault migration 절차가 필요하다.

## 11. 구현 순서 제안

1. OpenFHE Python에서 CKKS `2-of-2` joint keygen/decrypt 최소 spike를 만든다.
2. `pk_joint`로 암호화한 스칼라 ciphertext를 PC/phone share partial decrypt + fusion으로
   복원하는 테스트를 만든다.
3. BFV/BGV exact integer와 Boolean FHE 후보의 2-of-2 mobile backend 지원을 각각 spike한다.
4. Record별 AEAD DEK와 2-of-2 threshold envelope round-trip을 검증한다.
5. fusion 위치를 PC와 phone 두 모드로 나누어 threat model을 검증한다.
6. 단일키 bundle과 호환되지 않는 새 multiparty bundle version을 정의한다.
7. `RevealPolicy`에 fusion destination과 `phone_display_only` 결정을 추가한다.
8. 주민등록번호 exact-envelope + phone-fusion-only smoke test를 만든다.
9. 2-of-3 recovery / rotation / audit log를 별도 설계한다.

## 12. 참고자료

- OpenFHE documentation: <https://openfhe-development.readthedocs.io/en/latest/>
- OpenFHE examples page, `threshold-fhe.cpp`: <https://openfhe-development.readthedocs.io/en/latest/sphinx_rsts/intro/quickstart.html>
- OpenFHE threshold example source: <https://github.com/openfheorg/openfhe-development/blob/main/src/pke/examples/threshold-fhe.cpp>
- CKKS 원 논문, Cheon-Kim-Kim-Song, "Homomorphic Encryption for Arithmetic of Approximate Numbers": <https://doi.org/10.1007/978-3-319-70694-8_15>
- Multiparty HE survey, "Computing Blindfolded on Data Homomorphically Encrypted under Multiple Keys": <https://arxiv.org/abs/2007.09270>
- Threshold HE decryption-oracle risk discussion, "A Critical Look into Threshold Homomorphic Encryption for Private Average Aggregation": <https://arxiv.org/abs/2602.22037>
- CKKS security note, Li-Micciancio, "On the Security of Homomorphic Encryption on Approximate Numbers": <https://eprint.iacr.org/2020/1533>
- Android Keystore: <https://developer.android.com/privacy-and-security/keystore>
- Apple Secure Enclave: <https://support.apple.com/guide/security/secure-enclave-sec59b0b31ff/web>
