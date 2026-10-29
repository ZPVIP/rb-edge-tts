# frozen_string_literal: true

module RbEdgeTTS
  # Sec-MS-GEC v2 token: "<16 hex CS64>-<64 hex SHA-256>".
  #
  # Microsoft's service started rejecting the v1 token (plain SHA-256, version "1-...")
  # with HTTP 403. Ported from rany2/edge-tts 7.3.0 (src/edge_tts/drm.py), which
  # tracks the new digest. The SHA-256 here is a modified variant (tweaked schedule
  # words and round constants), so Digest::SHA256 cannot be used.
  module SecMsGecV2
    MASK = 0xFFFFFFFF

    SHA256_INITIAL = [
      0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
      0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19
    ].freeze

    # Working state after the first 14 rounds, which depend only on the fixed salt prefix.
    SHA256_STATE = [
      0xFD9FBEA2, 0x91243CE7, 0xBE499094, 0xCD2E1E0A,
      0x6C006F49, 0x04BD35AB, 0xFEB0A7E4, 0x03EFFBD2
    ].freeze

    SHA256_SCHEDULE = [
      0xEB24BF9E, 0x1558691F, 0xA0C09EE2, 0x0CFA32BA, 0xA622EE8C, 0xD1DD9491, 0xC0DD25A0,
      0xF9E70AB6, 0xF0C31573, 0x7058CE4E, 0x7188E606, 0x00E5AB33, 0xD258B060, 0x72766564
    ].freeze

    SHA256_ROUND_CONSTANTS = [
      0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
      0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
      0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
      0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
      0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
      0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
      0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
      0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
    ].freeze

    SHA256_ADJUSTMENT = 0xC9DC06A7
    SHA256_BLOCK_CONSTANTS = (SHA256_ROUND_CONSTANTS[0, 14] + [SHA256_ADJUSTMENT] + SHA256_ROUND_CONSTANTS[15..]).freeze
    SHA256_SIGMA0_ADJUSTMENT = 0x059C0B80
    SHA256_SIGMA1_ADJUSTMENT = 0x000B92C0

    CS64_COEFFICIENTS = [
      [0xE82E91B1, 0xB32700D0], [0x44DE24C6, 0x88DFF51D], [0x3BEB65BC, 0x29514038],
      [0xC89C5933, 0xB328CBDF], [0x8D1EC211, 0xD405B4D5], [0x314EF5D5, 0x26E55F3C],
      [0xE92491B1, 0x607801C6], [0xF0A5B9D5, 0x82B2C1FB], [0x06064CF3, 0xFA51A3DA],
      [0xDA79FA60, 0x207CC464], [0xBED20560, 0x3C3C74F3], [0x89F9C9F8, 0xD2D14B61],
      [0x35FA38C6, 0xBB04A2C1], [0xCB49E3C6, 0xC5626167]
    ].freeze
    CS64_FACTOR = 0x82893933
    CS64_ADJUSTMENT0 = 0xF2F90B1A
    CS64_ADJUSTMENT1 = 0x0B1A0000

    class << self
      # Returns the token for the 5-minute window containing +ticks+ (a Windows
      # file time in 100ns units, already rounded down to the window).
      def token(ticks, trusted_client_token)
        data = "#{ticks}#{trusted_client_token}".b
        digest = sha256_digest(data)
        cs64 = cs64_digest(data, digest).pack('VV').unpack1('H*').upcase
        "#{cs64}-#{digest.unpack1('H*').upcase}"
      end

      private

      def rol16(value)
        value &= MASK
        ((value << 16) | (value >> 16)) & MASK
      end

      def rotr(value, count)
        ((value >> count) | (value << (32 - count))) & MASK
      end

      def sigma0(value)
        rotr(value, 7) ^ rotr(value, 18) ^ (value >> 3)
      end

      def sigma1(value)
        rotr(value, 17) ^ rotr(value, 19) ^ (value >> 10)
      end

      def sha256_rounds(state, words, first_round = 0)
        a, b, c, d, e, f, g, h = state
        constants = first_round == 14 ? SHA256_BLOCK_CONSTANTS : SHA256_ROUND_CONSTANTS
        (first_round...64).each do |i|
          t1 = h + (rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)) + (g ^ (e & (f ^ g))) + constants[i] + words[i]
          t2 = (rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)) + ((a & b) | (c & (a | b)))
          a, b, c, d, e, f, g, h = (t1 + t2) & MASK, a, b, c, (d + t1) & MASK, e, f, g
        end
        [a, b, c, d, e, f, g, h]
      end

      def expand_schedule(words, first_word = 16)
        (first_word...64).each do |i|
          words << ((sigma1(words[i - 2]) + words[i - 7] + sigma0(words[i - 15]) + words[i - 16]) & MASK)
        end
      end

      # State after the salt's first 7 bytes, which are fixed for a given window token.
      def sha256_init(prefix)
        words = ([0] * 14) + [prefix[0, 3].unpack1('H*').to_i(16), prefix[3, 4].unpack1('N')]
        (16...30).each do |i|
          value = SHA256_SCHEDULE[i - 16]
          if i - 2 >= 14
            s1 = sigma1(words[i - 2])
            value += i == 16 ? s1 ^ SHA256_SIGMA1_ADJUSTMENT : s1
          end
          value += words[i - 7] if i - 7 >= 14
          if i - 15 >= 14
            s0 = sigma0(words[i - 15])
            value += i == 29 ? s0 ^ SHA256_SIGMA0_ADJUSTMENT : s0
          end
          words << (value & MASK)
        end
        words << ((sigma1(words[28]) + words[23] + sigma0(words[15]) + words[14] +
                   SHA256_ADJUSTMENT - SHA256_ROUND_CONSTANTS[14]) & MASK)
        expand_schedule(words, 31)
        working = sha256_rounds(SHA256_STATE, words, 14)
        SHA256_INITIAL.zip(working).map { |x, y| (x + y) & MASK }
      end

      def sha256_digest(data)
        raise ArgumentError, 'Token salt must contain at least seven bytes' if data.bytesize < 7

        length = 57 + data.bytesize
        padded = data.byteslice(7..) + "\x80".b + ("\x00".b * ((55 - length) % 64)) + [length * 8].pack('Q>')
        state = sha256_init(data.byteslice(0, 7))
        (0...padded.bytesize).step(64) do |offset|
          words = padded.byteslice(offset, 64).unpack('N16')
          expand_schedule(words)
          working = sha256_rounds(state, words)
          state = state.zip(working).map { |x, y| (x + y) & MASK }
        end
        state.pack('N8')
      end

      def words_le4_even(data)
        padded = data + ("\x00".b * ((-data.bytesize) % 4))
        words = padded.unpack('V*')
        words << 0 if words.size.odd?
        words
      end

      def cs64_digest(data, digest)
        key_a, key_b = digest.unpack('VV')
        key_a |= 1
        key_b |= 1
        factors = [(key_a * CS64_FACTOR) & MASK, (key_b * CS64_FACTOR) & MASK]
        terms = CS64_COEFFICIENTS.each_with_index.map { |(coefficient, _), i| (coefficient * factors[i % 2]) & MASK }
        offsets = CS64_COEFFICIENTS.map(&:last)

        words_le4_even("\x00".b + data).each_with_index do |word, i|
          term = word * (i.even? ? key_a : key_b)
          offset = rol16(word) * (i.even? ? 0xEF0569FB : 0xC31713DB)
          if i.zero?
            term += CS64_ADJUSTMENT0 * factors[0]
            offset += CS64_ADJUSTMENT1
          end
          terms << (term & MASK)
          offsets << (offset & MASK)
        end

        swap_acc = swap_last = state = acc = 0
        (0...terms.size).step(2) do |i|
          x = terms[i]
          y = terms[i + 1]
          t = rol16((offsets[i] + x) & MASK)
          q = (t * 0x76F50F34) & MASK
          swap_acc += (rol16(q) * 0xC3EFEA97 + q) & MASK
          t = rol16((offsets[i + 1] + y) & MASK)
          q = (t * 0x1881CE3C) & MASK
          swap_last = (rol16(q) * 0x35BD1EC9 + q) & MASK
          swap_acc = (swap_acc + swap_last) & MASK

          state = (state * key_a + x) & MASK
          state = (rol16(state) * 0xCF98B111) & MASK
          state = (rol16(state) * 0x87085B9F) & MASK
          state = (rol16(state) * 0x12CEB96D) & MASK
          state = (rol16(state) * 0x257E1D83) & MASK
          acc += state
          t = (state * key_b + y) & MASK
          t = (rol16(t) * 0xA27416F5) & MASK
          t = (rol16(t) * 0xD38396FF) & MASK
          state = (rol16((rol16(t) * 0x7C932B89) & MASK) * 0xBFA49F69) & MASK
          acc = (acc + state) & MASK
        end
        [swap_last ^ state, swap_acc ^ acc]
      end
    end
  end
end
