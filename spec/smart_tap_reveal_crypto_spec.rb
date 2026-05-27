# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessGrid::SmartTapRevealCrypto do
  # Captured wire-compat fixture — opaque server output. Proves the SDK's
  # decrypt path is wire-compatible without reproducing server encryption
  # in test code. caller_private_key is ephemeral and single-use by design.
  let(:fixture_caller_private_key_pem) do
    <<~PEM
      -----BEGIN EC PRIVATE KEY-----
      MHcCAQEEIIou+Kk08kWAjhi0WyIx+L2GrgStGBCPODlwKYKd5BydoAoGCCqGSM49
      AwEHoUQDQgAE+gnDxXJt1SBaCK8roKH8QvOa/ItdQUe85JIsUc6RvhD/udLaFtHY
      m+MnOmeSdVaKTPWudH0+iGbleB3kS7lYxQ==
      -----END EC PRIVATE KEY-----
    PEM
  end

  let(:fixture_envelope) do
    {
      'alg' => 'ECDH-ES+A256GCM',
      'ciphertext' => 'ckYyA3FdRYjOFI/FKz/QeR5Yf9nZZFzo73kDXKZSB/EgbQ==',
      'ephemeral_public_key' =>
        "-----BEGIN PUBLIC KEY-----\n" \
        "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7mg6i99GcIVutMPr/PXSBSQVlbLM\n" \
        "tnJO10ZBjk9ZTfw6wwAVNBnDBiqY7VrdOG1JdFOYoac+NkAlyMRGYk2tVQ==\n" \
        "-----END PUBLIC KEY-----\n",
      'iv' => '5X2OCht+kLB/xQmX',
      'tag' => '0vwkjVaCwi5zl37xvJPxeg=='
    }
  end

  let(:fixture_priv) { OpenSSL::PKey::EC.new(fixture_caller_private_key_pem) }
  let(:fixture_expected_plaintext) { 'FIXTURE-PLAINTEXT-NOT-A-CREDENTIAL' }

  describe '.decrypt_envelope' do
    it 'decrypts the captured server-produced envelope' do
      plaintext = described_class.decrypt_envelope(fixture_envelope, fixture_priv)
      expect(plaintext).to eq(fixture_expected_plaintext)
    end

    it 'raises when the auth tag is tampered' do
      tag = Base64.decode64(fixture_envelope['tag'])
      tag = (tag[0].ord ^ 0x01).chr + tag[1..]
      tampered = fixture_envelope.merge('tag' => Base64.strict_encode64(tag))

      expect { described_class.decrypt_envelope(tampered, fixture_priv) }
        .to raise_error(AccessGrid::DecryptError, /decryption failed/i)
    end

    it 'raises when a different private key is used' do
      wrong = OpenSSL::PKey::EC.generate('prime256v1')
      expect { described_class.decrypt_envelope(fixture_envelope, wrong) }
        .to raise_error(AccessGrid::DecryptError, /decryption failed/i)
    end

    it 'raises when ephemeral_public_key is missing' do
      bad = fixture_envelope.dup.tap { |e| e.delete('ephemeral_public_key') }
      expect { described_class.decrypt_envelope(bad, fixture_priv) }
        .to raise_error(AccessGrid::InvalidEnvelopeError, /ephemeral_public_key/)
    end

    it 'raises when iv is not valid base64' do
      bad = fixture_envelope.merge('iv' => 'not!base64!')
      expect { described_class.decrypt_envelope(bad, fixture_priv) }
        .to raise_error(AccessGrid::InvalidEnvelopeError, /base64/i)
    end
  end

  describe '.generate_keypair' do
    it 'returns a priv/pub_pem pair' do
      keypair = described_class.generate_keypair
      expect(keypair).to include(:priv, :pub_pem)
    end

    it 'returns a P-256 EC private key' do
      keypair = described_class.generate_keypair
      expect(keypair[:priv]).to be_a(OpenSSL::PKey::EC)
      expect(keypair[:priv].group.curve_name).to eq('prime256v1')
    end

    it 'returns a parseable SubjectPublicKeyInfo PEM matching the private key' do
      keypair = described_class.generate_keypair
      expect(keypair[:pub_pem]).to include('-----BEGIN PUBLIC KEY-----')

      reloaded = OpenSSL::PKey::EC.new(keypair[:pub_pem])
      expect(reloaded.public_key.to_octet_string(:uncompressed))
        .to eq(keypair[:priv].public_key.to_octet_string(:uncompressed))
    end

    it 'produces distinct keypairs on each call' do
      a = described_class.generate_keypair
      b = described_class.generate_keypair
      expect(a[:pub_pem]).not_to eq(b[:pub_pem])
    end
  end
end
