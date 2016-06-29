/**
 Copyright © 2015, 2016 Odzhan. All Rights Reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.

 3. The name of the author may not be used to endorse or promote products
 derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY AUTHORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE. */

#include "sha3.h"

// round constant function
// Primitive polynomial over GF(2): x^8+x^6+x^5+x^4+1
uint64_t rc(uint8_t *LFSR)
{
    uint64_t c;
    uint32_t i, t;

    c = 0;
    t = *LFSR;

    for (i=1; i<128; i += i)
    {
        if (t & 1) {
            c ^= (uint64_t)1ULL << (i - 1);
        }
        t = (t & 0x80) ? (t << 1) ^ 0x71 : t << 1;
    }
    *LFSR = (uint8_t)t;
    return c;
}

const uint8_t keccakf_piln[24] =
{ 10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
    15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1  };

#define ROTL64(x, y) (((x) << (y)) | ((x) >> (64 - (y))))

void SHA3Transform(SHA3CTX *ctx)
{
    uint32_t i, j, rnd, r;
    uint64_t t, bc[5];
    uint64_t *st=(uint64_t*)ctx->state.v64;
    uint8_t lfsr=1;

    for (rnd=0; rnd<SHA3_ROUNDS; rnd++)
    {
        // Theta
        for (i=0; i<5; i++) {
            bc[i] = st[i]
            ^ st[i + 5]
            ^ st[i + 10]
            ^ st[i + 15]
            ^ st[i + 20];
        }
        for (i=0; i<5; i++) {
            t = bc[(i + 4) % 5] ^ ROTL64(bc[(i + 1) % 5], 1);
            for (j=0; j<25; j+=5) {
                st[j + i] ^= t;
            }
        }

        // Rho Pi
        t = st[1];
        for (i=0, r=0; i<24; i++) {
            r += i + 1;
            j = keccakf_piln[i];
            bc[0] = st[j];
            st[j] = ROTL64(t, r & 63);
            t = bc[0];
        }

        // Chi
        for (j=0; j<25; j+=5) {
            for (i=0; i<5; i++) {
                bc[i] = st[j + i];
            }
            for (i=0; i<5; i++) {
                st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
            }
        }
        // Iota
        st[0] ^= rc(&lfsr);
    }
}

// mdlen isn't checked, it presumes caller provides 28,32,48 or 64
void SHA3Init(SHA3CTX *ctx, SHA3_BitSize mdlen)
{
    uint32_t i = 0;

    ctx->outlen = mdlen;
    ctx->buflen = 200 - (2 * mdlen);
    ctx->index  = 0;

    for (i=0; i<SHA3_STATE_LEN; i++) {
        ctx->state.v64[i] = 0;
    }
}

void SHA3Update(SHA3CTX* ctx, void *in, uint32_t inlen)
{
    uint32_t i;

    // update buffer and state
    for (i=0; i<inlen; i++) {
        if (ctx->index == ctx->buflen) {
            SHA3Transform (ctx);
            ctx->index = 0;
        }
        // absorb byte into state
        ctx->state.v8[ctx->index++] ^= ((uint8_t*)in)[i];
    }
}

void SHA3Final(void* out, SHA3CTX* ctx)
{
    uint32_t i = 0;
    // absorb 3 bits, Keccak uses 1
    ctx->state.v8[ctx->index] ^= 6;
    // absorb end bit
    ctx->state.v8[(ctx->buflen)-1] ^= 0x80;
    // update context
    SHA3Transform (ctx);
    // copy digest to buffer
    for (i=0; i < (ctx->outlen); i++) {
        ((uint8_t*)out)[i] = (ctx->state).v8[i];
    }
}

// calls SHA-3 once to create MAC of data or just plain SHA3
void sha3_mac (void *in, uint32_t inlen,
               void *key, uint32_t keylen,
               void *out, SHA3_BitSize mdlen)
{
    SHA3CTX ctx;
    
    // initialize context
    SHA3Init (&ctx, mdlen);
    
    // prepend the key
    SHA3Update (&ctx, key, keylen);
    
    // add data
    SHA3Update (&ctx, in, inlen);
    
    // finalize
    SHA3Final (out, &ctx);
}