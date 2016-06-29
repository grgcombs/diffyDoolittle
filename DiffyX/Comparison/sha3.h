/**
 Copyright © 2015 Odzhan. All Rights Reserved.

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

#ifndef SHA3H
#define SHA3H

//#include <stdint.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SHA3_BitSize) {
    SHA3_224 = 28,
    SHA3_256 = 32,
    SHA3_384 = 48,
    SHA3_512 = 64
};

#define SHA3_ROUNDS             24
#define SHA3_STATE_LEN          25

#define SHA3_224_DIGEST_LENGTH  SHA3_224
#define SHA3_224_CBLOCK        144

#define SHA3_256_DIGEST_LENGTH  SHA3_256
#define SHA3_256_CBLOCK        136

#define SHA3_384_DIGEST_LENGTH  SHA3_384
#define SHA3_384_CBLOCK        104

#define SHA3_512_DIGEST_LENGTH  SHA3_512
#define SHA3_512_CBLOCK         72

typedef union sha3_st_t {
    uint8_t  v8[SHA3_STATE_LEN*8];
    uint16_t v16[SHA3_STATE_LEN*4];
    uint32_t v32[SHA3_STATE_LEN*2];
    uint64_t v64[SHA3_STATE_LEN];
} sha3_st;

//#pragma pack(push, 1)
typedef struct SHA3CTX {
    uint32_t outlen;
    uint32_t buflen;
    uint32_t index;

    sha3_st state;
} SHA3CTX;
//#pragma pack(pop)

void SHA3Init(SHA3CTX *, SHA3_BitSize);
void SHA3Update(SHA3CTX*, void *, uint32_t);
void SHA3Final(void*, SHA3CTX*);

#endif