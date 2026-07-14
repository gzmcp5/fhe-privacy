from __future__ import annotations

import math
import sys

import openfhe as fhe


def exact_scheme(params_type: type, name: str) -> None:
    params = params_type()
    params.SetPlaintextModulus(65537)
    params.SetMultiplicativeDepth(1)
    context = fhe.GenCryptoContext(params)
    context.Enable(fhe.PKE)
    context.Enable(fhe.KEYSWITCH)
    context.Enable(fhe.LEVELEDSHE)
    keys = context.KeyGen()
    left = context.MakePackedPlaintext([1, 2, 3, 4])
    right = context.MakePackedPlaintext([4, 3, 2, 1])
    result = context.Decrypt(
        context.EvalAdd(
            context.Encrypt(keys.publicKey, left),
            context.Encrypt(keys.publicKey, right),
        ),
        keys.secretKey,
    )
    result.SetLength(4)
    actual = list(result.GetPackedValue())
    assert actual == [5, 5, 5, 5], (name, actual)
    print(f"PASS {name}: {actual}")


def ckks() -> None:
    params = fhe.CCParamsCKKSRNS()
    params.SetMultiplicativeDepth(1)
    params.SetScalingModSize(50)
    params.SetBatchSize(4)
    context = fhe.GenCryptoContext(params)
    context.Enable(fhe.PKE)
    context.Enable(fhe.KEYSWITCH)
    context.Enable(fhe.LEVELEDSHE)
    keys = context.KeyGen()
    left = context.MakeCKKSPackedPlaintext([0.25, 0.5, 0.75, 1.0])
    right = context.MakeCKKSPackedPlaintext([1.0, 0.75, 0.5, 0.25])
    result = context.Decrypt(
        context.EvalAdd(
            context.Encrypt(keys.publicKey, left),
            context.Encrypt(keys.publicKey, right),
        ),
        keys.secretKey,
    )
    result.SetLength(4)
    actual = [value.real for value in result.GetCKKSPackedValue()]
    assert all(math.isclose(value, 1.25, abs_tol=1e-6) for value in actual), actual
    print(f"PASS CKKS: {actual}")


def boolean_fhe() -> None:
    context = fhe.BinFHEContext()
    context.GenerateBinFHEContext(fhe.TOY, fhe.GINX)
    secret = context.KeyGen()
    context.BTKeyGen(secret)
    one = context.Encrypt(secret, 1)
    zero = context.Encrypt(secret, 0)
    assert context.Decrypt(secret, context.EvalBinGate(fhe.AND, one, zero)) == 0
    assert context.Decrypt(secret, context.EvalBinGate(fhe.OR, one, zero)) == 1
    print("PASS Boolean FHE: AND=0 OR=1")


def multiparty_two_of_two() -> None:
    params = fhe.CCParamsBGVRNS()
    params.SetPlaintextModulus(65537)
    params.SetMultiplicativeDepth(0)
    params.SetKeySwitchTechnique(fhe.BV)
    params.SetDigitSize(10)
    params.SetMultipartyMode(fhe.NOISE_FLOODING_MULTIPARTY)
    context = fhe.GenCryptoContext(params)
    context.Enable(fhe.PKE)
    context.Enable(fhe.KEYSWITCH)
    context.Enable(fhe.LEVELEDSHE)
    context.Enable(fhe.ADVANCEDSHE)
    context.Enable(fhe.MULTIPARTY)

    pc_party = context.KeyGen()
    phone_party = context.MultipartyKeyGen(pc_party.publicKey)
    assert pc_party.good() and phone_party.good()
    plaintext = context.MakePackedPlaintext([7, 11, 13, 17])
    ciphertext = context.Encrypt(phone_party.publicKey, plaintext)
    pc_partial = context.MultipartyDecryptLead([ciphertext], pc_party.secretKey)
    phone_partial = context.MultipartyDecryptMain([ciphertext], phone_party.secretKey)
    result = context.MultipartyDecryptFusion([pc_partial[0], phone_partial[0]])
    result.SetLength(4)
    actual = list(result.GetPackedValue())
    assert actual == [7, 11, 13, 17], actual
    print(f"PASS BGV 2-of-2 partial decrypt/fusion: {actual}")


if __name__ == "__main__":
    assert sys.version_info[:2] == (3, 13), sys.version
    exact_scheme(fhe.CCParamsBFVRNS, "BFV")
    exact_scheme(fhe.CCParamsBGVRNS, "BGV")
    ckks()
    boolean_fhe()
    multiparty_two_of_two()
