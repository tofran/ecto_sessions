defmodule EctoSessions.AuthTokenTest do
  use ExUnit.Case, async: true

  alias EctoSessions.AuthToken

  describe "hash" do
    test "using configuration" do
      assert AuthToken.hash("sample") ==
               "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"
    end

    test "sha256" do
      assert AuthToken.hash(:sha256, "sample") ==
               "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"
    end

    test "sha512" do
      assert AuthToken.hash(:sha512, "sample") ==
               "39a5e04aaff7455d9850c605364f514c11324ce64016960d23d5dc57d3ffd8f4" <>
                 "9a739468ab8049bf18eef820cdb1ad6c9015f838556bc7fad4138b23fdf986c7"
    end

    test "sha3_256" do
      assert AuthToken.hash(:sha3_256, "sample") ==
               "f68f564e181663381ef67ae5849d3dd1d0f1044cf468d0a0b7875e4ff121906f"
    end

    test "blake2b" do
      assert AuthToken.hash(:blake2b, "sample") ==
               "cc6c2d671173dd85a4ef30b0376d14980c20e54c69752fceb4abf6e583924309" <>
                 "e15981e6aa728e9127d5a422b1afdd5cbe1a5d0097f34186f78424d5f3588859"
    end
  end

  describe "add_salt" do
    test "using configuration" do
      assert AuthToken.add_salt("sample") == "sample"
    end

    test "passing nil (not salting)" do
      assert AuthToken.add_salt("sample", nil) == "sample"
    end

    test "passing salt" do
      assert AuthToken.add_salt("sample", "my-salt") == "my-saltsample"
    end
  end

  test "get_auth_token/0" do
    assert {plaintext_auth_token, hashed_auth_token} = AuthToken.get_auth_token()
    assert hashed_auth_token == AuthToken.hash(plaintext_auth_token)
  end
end
