# frozen_string_literal: true

require 'openssl'
require 'base64'

module AccessGrid
  # Internal crypto helpers for the SmartTap reveal flow.
  #
  # Driven by Console#reveal_smart_tap; not part of the public SDK surface.
  # Pure stdlib — no new gem deps.
  #
  # @api private
  module SmartTapRevealCrypto
    CURVE = 'prime256v1'
    HKDF_INFO = 'accessgrid-smart-tap-reveal-v1'
    KEY_LEN = 32

    # Generate a fresh ephemeral P-256 keypair for a reveal call.
    #
    # @return [Hash] `{priv: OpenSSL::PKey::EC, pub_pem: String}`
    def self.generate_keypair
      priv = OpenSSL::PKey::EC.generate(CURVE)
      { priv: priv, pub_pem: priv.public_to_pem }
    end

    # Decrypt the encrypted_private_key envelope from the reveal endpoint.
    #
    # Performs ECDH(client_priv, server_ephemeral_pub) + HKDF-SHA256 +
    # AES-256-GCM. Must match the server-side encryption parameters exactly.
    #
    # @return [String] the plaintext SmartTap private key PEM.
    # @raise [RuntimeError] on missing/bad envelope or auth-tag verification failure.
    def self.decrypt_envelope(envelope, priv)
      server_pub = parse_ephemeral_public_key(envelope)
      nonce = decode_envelope_bytes(envelope['iv'])
      ciphertext = decode_envelope_bytes(envelope['ciphertext'])
      tag = decode_envelope_bytes(envelope['tag'])

      aes_key = derive_aes_key(priv, server_pub)
      aes_gcm_decrypt(aes_key, nonce, ciphertext, tag)
    end

    # @api private
    def self.parse_ephemeral_public_key(envelope)
      pem = envelope['ephemeral_public_key']
      raise InvalidEnvelopeError, 'Invalid ephemeral_public_key in envelope' unless pem.is_a?(String) && !pem.empty?

      OpenSSL::PKey::EC.new(pem)
    end

    # @api private
    def self.derive_aes_key(priv, server_pub)
      shared_secret = priv.dh_compute_key(server_pub.public_key)
      OpenSSL::KDF.hkdf(shared_secret, salt: '', info: HKDF_INFO, length: KEY_LEN, hash: 'SHA256')
    end

    # @api private
    def self.aes_gcm_decrypt(aes_key, nonce, ciphertext, tag)
      cipher = OpenSSL::Cipher.new('aes-256-gcm').decrypt
      cipher.key = aes_key
      cipher.iv = nonce
      cipher.auth_tag = tag
      cipher.auth_data = ''
      cipher.update(ciphertext) + cipher.final
    rescue OpenSSL::Cipher::CipherError
      raise DecryptError, 'AES-GCM decryption failed (auth tag verification)'
    end

    # @api private
    def self.decode_envelope_bytes(value)
      raise InvalidEnvelopeError, 'Envelope iv/ciphertext/tag must be base64-encoded' unless value.is_a?(String)

      Base64.strict_decode64(value)
    rescue ArgumentError
      raise InvalidEnvelopeError, 'Envelope iv/ciphertext/tag must be base64-encoded'
    end
  end
end
