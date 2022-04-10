defmodule EctoSessions.AuthTokenTest do
  use ExUnit.Case, async: true

  import EctoSessions.AuthToken

  doctest EctoSessions.AuthToken

  describe "generate_token/1" do
    test "success with length 128" do
      assert generate_token(128) =~ ~r/^[A-z0-9\_\-]{128}$/
    end

    test "success with length 16" do
      assert generate_token(16) =~ ~r/^[A-z0-9\_\-]{16}$/
    end

    test "error with length 15" do
      assert_raise RuntimeError, "The auth token length must be at least 16 (128 bits)", fn ->
        generate_token(15)
      end
    end
  end

  describe "get_digest/3" do
    test "success no hashing" do
      assert get_digest("sample", nil, nil) == "sample"
    end

    test "success hashing" do
      assert get_digest("sample", :sha256, nil) ==
               "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"
    end

    test "success hashing with salt" do
      assert get_digest("sample", :sha256, "super-secret") ==
               "9b6245c496f31244d30201dcdc6afd51171a460bc19c75200f04ab48d39ebbe4"
    end

    test "error attempt to salt without hashing" do
      assert_raise RuntimeError,
                   "Cannot salt a token that is not hashed. When hashing_algorithm is nil secret_salt must also be nil.",
                   fn ->
                     get_digest("sample", nil, "super-secret")
                   end
    end
  end

  describe "hash/2" do
    test "success with sha256" do
      assert hash("sample", :sha256) ==
               "af2bdbe1aa9b6ec1e2ade1d694f41fc71a831d0268e9891562113d8a62add1bf"
    end

    test "error empty token" do
      assert_raise RuntimeError, "Aborted attempt to hash empty token.", fn ->
        hash("", :sha256)
      end
    end

    test "error nil token" do
      assert_raise RuntimeError, "Aborted attempt to hash empty token.", fn ->
        hash("", :sha256)
      end
    end
  end
end
