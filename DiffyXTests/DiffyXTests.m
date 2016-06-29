//
//  DiffyXTests.m
//  DiffyXTests
//
//  Created by Gregory Combs on 6/27/16.
//  Copyright © 2016 Sleestacks. All rights reserved.
//

#import <XCTest/XCTest.h>
#include "sha3.h"
#include <sys/stat.h>

char *inputText[] =
{ "",
    "a",
    "abc",
    "message digest",
    "abcdefghijklmnopqrstuvwxyz",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890", "1F42ADD25C0A80A4C82AAE3A0E302ABF9261DCA7E7884FD869D96ED4CE88AAAA25304D2D79E1FA5CC1FA2C95899229BC87431AD06DA524F2140E70BD0536E9685EE7808F598D8A9FE15D40A72AEFF431239292C5F64BDB7F620E5D160B329DEB58CF6D5C0665A3DED61AE4ADBCA94DC2B7B02CDF3992FDF79B3D93E546D5823C3A630923064ED24C3D974C4602A49DF75E49CF7BD51EDC7382214CBA850C4D3D11B40A70B1D926E3755EC79693620C242AB0F23EA206BA337A7EDC5421D63126CB6C7094F6BC1CF9943796BE2A0D9EB74FC726AA0C0D3B3D39039DEAD39A7169F8C3E2365DD349E358BF08C717D2E436D65172A76ED5E1F1E694A75C19280B15"
};

char *outputDigest[] =
{ "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a",
    "80084bf2fba02475726feb2cab2d8215eab14bc6bdd8bfb2c8151257032ecd8b",
    "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
    "edcdb2069366e75243860c18c3a11465eca34bce6143d30c8665cefcfd32bffd",
    "7cab2dc765e21b241dbc1c255ce620b29f527c6d5e7f5f843e56288f0d707521",
    "a79d6a9da47f04a3b9a9323ec9991f2105d4c78a7bc7beeb103855a7a11dfb9f",
    "293e5ce4ce54ee71990ab06e511b7ccd62722b1beb414f5ff65c8274e0f5be1d",
    "eda9d864171fbba7de3808c1d441289c5c213843453cf3f931850fb3ca4a5de6"
};

size_t hex2bin (void *bin, char hex[]) {
    size_t len, i;
    int x;
    uint8_t *p=(uint8_t*)bin;

    len = strlen (hex);

    if ((len & 1) != 0) {
        return 0;
    }

    for (i=0; i<len; i++) {
        if (isxdigit((int)hex[i]) == 0) {
            return 0;
        }
    }

    for (i=0; i<len / 2; i++) {
        sscanf (&hex[i * 2], "%2x", &x);
        p[i] = (uint8_t)x;
    }
    return len / 2;
}

// print digest
void testPrint (uint8_t dgst[], size_t len)
{
    size_t i;
    for (i=0; i<len; i++) {
        printf ("%02x", dgst[i]);
    }
    putchar ('\n');
}

// generate SHA-3 hash of string
void testString(char *str, char *key, SHA3_BitSize type)
{
    SHA3CTX ctx;
    uint8_t  dgst[256];
    char     *hdrs[]={ "SHA3-224", "SHA3-256",
        "SHA3-384", "SHA3-512" };

    printf("\n%s(\"%s\")\n0x", hdrs[type], str);

    SHA3Init(&ctx, type);
    // prepend a key?
    if (key!=NULL) {
        SHA3Update(&ctx, key, (uint32_t)(strlen(key)));
    }
    SHA3Update(&ctx, str, (uint32_t) strlen(str));
    SHA3Final(dgst, &ctx);

    testPrint(dgst, ctx.outlen);
}

void logTestProgress(uint64_t fs_complete, uint64_t fs_total)
{
    int days=0, hours=0, minutes=0;
    uint64_t t, pct, speed, seconds=0;
    static time_t start=0;

    if (start==0) {
        start=time(0);
        return;
    }

    pct = (100*fs_complete)/fs_total;

    t = (time(0) - start);

    if (t != 0) {
        seconds = (fs_total - fs_complete) / (fs_complete / t);
        speed = (fs_complete / t);

        days=0;
        hours=0;
        minutes=0;

        if (seconds>=60) {
            minutes = (seconds / 60.f);
            seconds %= 60;
            if (minutes>=60) {
                hours = minutes / 60;
                minutes %= 60;
                if (hours>=24) {
                    days = hours/24;
                    hours %= 24;
                }
            }
        }
        NSLog(@"\rProcessed %llu MB out of %llu MB %llu MB/s : %llu%% complete. ETA: %03d:%02d:%02d:%02d    ",
              fs_complete/1000/1000, fs_total/1000/1000, speed/1000/1000, pct, days, hours, minutes, (int)seconds);
    }
}

// generate SHA-3 hash of file
void SHA3File(char fn[], char *key, SHA3_BitSize type)
{
    FILE     *fd;
    SHA3CTX ctx;
    size_t   len;
    uint8_t  buf[4096+1], dgst[256];
    struct stat st;
    uint32_t cmp=0, total=0;

    fd = fopen (fn, "rb");

    if (fd!=NULL)
    {
        stat(fn, &st);
        total=st.st_size;

        SHA3Init (&ctx, type);

        // prepend a key?
        if (key!=NULL) {
            SHA3Update(&ctx, key, strlen(key));
        }
        while ((len = fread (buf, 1, 4096, fd))!=0) {
            cmp += len;
            if (total > 10000000 && ((cmp % 10000000)==0 || cmp==total)) {
                logTestProgress(cmp, total);
            }
            SHA3Update(&ctx, buf, len);
        }
        SHA3Final (dgst, &ctx);

        fclose (fd);

        printf ("\n  [ SHA3-%d (%s) = ", ctx.outlen*8, fn);
        testPrint (dgst, ctx.outlen);
    } else {
        printf ("  [ unable to open %s\n", fn);
    }
}

@interface DiffyXTests : XCTestCase

@end

@implementation DiffyXTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testShaTests
{
    uint32_t passes = 0;
    uint32_t fails = 0;

    uint8_t  dgst_out[256], buf[2048], dgst_in[256];
    size_t i = 0, dgst_len = 0;
    uint32_t inlen = 0;
    SHA3CTX ctx;
    unsigned char *input = NULL;
    int tv_cnt=sizeof(inputText)/sizeof(char*);

    for (i=0; i<tv_cnt; i++)
    {
        // convert the digest to binary
        dgst_len=hex2bin(dgst_in, outputDigest[i]);

        // if this is the last one, convert the string to binary
        if ((i+1)==tv_cnt) {
            memset (buf, sizeof (buf), 0);
            input=buf;
            inlen=hex2bin(buf, inputText[i]);
        } else {
            // just use string itself
            input=inputText[i];
            inlen = strlen(input);
        }
        // get hash
        SHA3Init(&ctx, (SHA3_BitSize)dgst_len);
        SHA3Update(&ctx, input, (uint32_t)inlen);
        SHA3Final(dgst_out, &ctx);

        if (memcmp (dgst_in, dgst_out, ctx.outlen) != 0) {
            printf ("\nFailed for string \"%s\"", inputText[i]);
            ++fails;
        }
    }

    XCTAssertEqual(fails,0, @"Should have zero test failures");
    XCTAssertEqual(passes,tv_cnt, @"Should have %d test passes", tv_cnt);
}

@end
