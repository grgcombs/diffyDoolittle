//
//  Sha3Tests.m
//  DiffyX
//
//  Created by Gregory Combs on 6/27/16.
//  Copyright © 2016 Sleestacks. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "sha3.h"
#include <sys/stat.h>

char *inputText[] =
{
    "",
    "a",
    "abc",
    "message digest",
    "abcdefghijklmnopqrstuvwxyz",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890",

    // final test case
    "1F42ADD25C0A80A4C82AAE3A0E302ABF9261DCA7E7884FD869D96ED4CE88AAAA25304D2D79E1FA5C" \
    "C1FA2C95899229BC87431AD06DA524F2140E70BD0536E9685EE7808F598D8A9FE15D40A72AEFF431" \
    "239292C5F64BDB7F620E5D160B329DEB58CF6D5C0665A3DED61AE4ADBCA94DC2B7B02CDF3992FDF7" \
    "9B3D93E546D5823C3A630923064ED24C3D974C4602A49DF75E49CF7BD51EDC7382214CBA850C4D3D" \
    "11B40A70B1D926E3755EC79693620C242AB0F23EA206BA337A7EDC5421D63126CB6C7094F6BC1CF9" \
    "943796BE2A0D9EB74FC726AA0C0D3B3D39039DEAD39A7169F8C3E2365DD349E358BF08C717D2E436" \
    "D65172A76ED5E1F1E694A75C19280B15"
};

char *outputDigest[] =
{
    "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a",
    "80084bf2fba02475726feb2cab2d8215eab14bc6bdd8bfb2c8151257032ecd8b",
    "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
    "edcdb2069366e75243860c18c3a11465eca34bce6143d30c8665cefcfd32bffd",
    "7cab2dc765e21b241dbc1c255ce620b29f527c6d5e7f5f843e56288f0d707521",
    "a79d6a9da47f04a3b9a9323ec9991f2105d4c78a7bc7beeb103855a7a11dfb9f",
    "293e5ce4ce54ee71990ab06e511b7ccd62722b1beb414f5ff65c8274e0f5be1d",

    // final test case
    "eda9d864171fbba7de3808c1d441289c5c213843453cf3f931850fb3ca4a5de6"
};


@interface Sha3Tests : XCTestCase

@end

@implementation Sha3Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (size_t)hex2bin:(void *)bin hex:(char *)hex
{
    if (!hex)
        return 0;

    uint8_t *p = (uint8_t *)bin;
    size_t hexLength = strlen (hex);

    if ((hexLength & 1) != 0)
        return 0; // Bail if it's an odd, not even length.  Hex values come in pairs.

    // Ensure we only have hexidecimal character values in the hex string
    for (size_t i = 0; i < hexLength; i++)
    {
        int character = (int)hex[i];
        if (isxdigit(character) == 0)
            return 0;
    }

    // step through the hex pairs
    for (size_t i = 0; i < hexLength / 2; i++)
    {
        int x = 0;
        sscanf (&hex[i * 2], "%2x", &x);
        p[i] = (uint8_t)x;
    }

    return (hexLength / 2);
}

- (void)executeHashTestCaseWithId:(size_t)testCaseId
{
    size_t testCaseCount = sizeof(inputText) / sizeof(char *);
    NSAssert(testCaseId < testCaseCount, @"Invalid test case ID: %ld", testCaseId);

    uint8_t digestOutput[256];
    uint8_t digestInput[256];
    SHA3CTX context;

    char *input = NULL;
    size_t inputLength = 0;

    // if this is the last test case, convert the string to binary first
    if ((testCaseId + 1) == testCaseCount)
    {
        char buf[2048];
        memset(buf, sizeof(buf), 0);
        input = buf;
        inputLength = [self hex2bin:buf hex:inputText[testCaseId]];
    }
    else
    {
        input = inputText[testCaseId];
        inputLength = strlen(input);
    }

    char *expected = outputDigest[testCaseId];
    size_t expectedLength = [self hex2bin:digestInput hex:expected];

    SHA3Init(&context, (SHA3_BitSize)expectedLength);
    SHA3Update(&context, input, (uint32_t)inputLength);
    SHA3Final(digestOutput, &context);

    XCTAssertEqual(memcmp(digestInput, digestOutput, context.outlen), 0, @"(SHA Test Case %ld): Unexpected SHA digest for '%s'. %s is not  %s", testCaseId, input, digestInput, digestOutput);
}

- (void)testShaTestCases
{
    size_t testCaseCount = sizeof(inputText) / sizeof(char *);
    for (size_t testCaseId = 0; testCaseId < testCaseCount; testCaseId++)
    {
        [self executeHashTestCaseWithId:testCaseId];
    }
}

- (void)testShaTests
{
    uint32_t passes = 0;
    uint32_t fails = 0;
    char *input = NULL;

    char dgst_out[256], buf[2048], dgst_in[256];
    SHA3CTX ctx;
    int tv_cnt = sizeof(inputText) / sizeof(char *);

    for (size_t i = 0; i < tv_cnt; i++)
    {
        // convert the digest to binary
        size_t dgst_len = [self hex2bin:dgst_in hex:outputDigest[i]];
        size_t inlen = 0;

        // if this is the last one, convert the string to binary
        if ((i+1) == tv_cnt) {
            memset (buf, sizeof(buf), 0);
            input = buf;
            inlen = [self hex2bin:buf hex:inputText[i]];
        } else {
            // just use string itself
            input = inputText[i];
            inlen = strlen(input);
        }
        // get hash
        SHA3Init(&ctx, (SHA3_BitSize)dgst_len);
        SHA3Update(&ctx, input, (uint32_t)inlen);
        SHA3Final(dgst_out, &ctx);


        XCTAssertEqual(memcmp(dgst_in, dgst_out, ctx.outlen), 0, @"Unexpected SHA digest for '%s': %s is not  %s", input, dgst_in, dgst_out);
        if (memcmp(dgst_in, dgst_out, ctx.outlen) == 0)
        {
            passes++;
        }
        else
        {
            printf ("\nFailed for string \"%s\"", inputText[i]);
            ++fails;
        }
    }

    XCTAssertEqual(fails, 0, @"Should have zero test failures");
    XCTAssertEqual(passes, tv_cnt, @"Should have %d test passes", tv_cnt);
}

@end
