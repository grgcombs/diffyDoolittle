/*
Diffy Doolittle X -- A File and Directory Comparison Utility.
Copyright (C) 2002  Gregory S. Combs

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#import "Comparer.h"
#import "sha3.h"

@implementation Comparer

- (instancetype)init
{
    self = [super init];
    _logString = [[NSMutableString alloc] init];
    _logFile = @"";
    return self;
}

- (NSMutableArray<NSString *> *)listDirectory:(NSString *)pathString
{
    NSMutableArray *theArray = [[NSMutableArray alloc] init];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator<NSString *> *direnum = [fileManager enumeratorAtPath:pathString];

    // Collect directory information for pathString
    for (NSString *pname in direnum.allObjects)
    {
        if (self.progressCancelled)
            break;
        BOOL isDir = YES; // default to what we don't want
        NSString * fullPath = [[pathString stringByAppendingString:@"/"] stringByAppendingString:pname];
        // if ([[pname pathExtension] isEqualToString:@"rtfd"])
        // {
        //    [direnum skipDescendents]; // don't enumerate this directory
        // } else
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir])
        {
            if (isDir == NO)
            {   // it's a file, add the partial path to our array
                [theArray addObject:pname];
            }
        }
    }

    [theArray sortUsingSelector:@selector(compare:)];
    return theArray;
}

- (void)weedMissingFromArray:(NSMutableArray *)fromArray
                     InArray:(NSMutableArray *)inArray
                     InTitle:(NSString *)inTitle
{
    // Remove strings from FromArray that aren't in InArray

    // **** PSEUDO-CODE FOR WEEDING OUT ****
    // for each itemName in OldArray
    // 	  **check for cancelled
    //    if need to yield time, do it
    // 	  if itemName not in NewArray
    //		report it missing from new directory
    //		remove it from OldArray
    //
    // Repeat for itemName in NewArray    

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int loopCounter = 0;

    NSMutableArray *newArray = [fromArray mutableCopy];

    for (NSString *pname in fromArray)
    {
        if (self.progressCancelled)
            break;
        loopCounter++;
        if (loopCounter % 360 == 0) // yield some time once in a while
        {
            [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:0]];
            loopCounter = 0;
        }
        if ([inArray containsObject:pname] == false)
        {
            if ([prefs integerForKey:@"Report Missing"])
            {
                // ********** report missing from inArray
                [self.logString appendFormat:@"File Missing From %@: %@\n", inTitle, pname];
            }
            [newArray removeObject:pname];
        }
    }

    [fromArray setArray:newArray];
}

// Compare two directories that have the same heirarchy and file names within,
//   This is done after weeding out missing files.
- (void)compareDirectory:(NSString *)fromDir toDirectory:(NSString *)toDir
        withContents:(NSMutableArray *)heirarchy
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSString *pname = nil;
    int loopCounter = 0;
    double fileCount = 0;
    double maxFiles = [heirarchy count];
    BOOL isEqual = NO;
    NSMutableString *newFile = [NSMutableString string];
    NSMutableString *oldFile = [NSMutableString string];

    [self.progressBar setMinValue:0];
    [self.progressBar setMaxValue:maxFiles];
    [self.progressBar setIndeterminate:NO];

    NSEnumerator *iter = [heirarchy objectEnumerator];
    while ((self.progressCancelled == NO) && (pname = [iter nextObject]))
    {
        loopCounter++;
        if (loopCounter % 360 == 0) // yield some time once in a while
        {
            [NSThread sleepUntilDate:[[NSDate date] addTimeInterval:0]];
            loopCounter = 0;
        }

        fileCount++;
        [self.progressBar setDoubleValue:fileCount];

        [self.progressMsg setStringValue:pname];

        // Reset our baseline path
        [newFile setString:[fromDir stringByAppendingString:@"/"]];
        [oldFile setString:[toDir stringByAppendingString:@"/"]];

        // Add filename from heirarchy
        [newFile appendString:pname];
        [oldFile appendString:pname];
        
        // Compare two files for equality.  Returning > 0 means equal.
        isEqual = [self compareNewFile:newFile toOldFile:oldFile];

        if (!isEqual && ([prefs integerForKey:@"Report Different"]))
        {
            // ********** report different files
            [self.logString appendFormat:@"Files are different: %@\n", pname];
        }
        else if (isEqual && ([prefs integerForKey:@"Report Identical"]))
        {
            // ********** report indentical files
            [self.logString appendFormat:@"Files are indentical: %@\n", pname];
        }
        if (isEqual && ([prefs integerForKey:@"Delete Identical"]))
        {
            // ********** delete indentical files
            [[NSFileManager defaultManager] removeFileAtPath:newFile handler:nil];
            [[NSFileManager defaultManager] removeFileAtPath:oldFile handler:nil];
        }
    }
}

- (IBAction)progressCancel:(id)sender
{
    self.progressCancelled = YES;
}

// Compare two directories using our preferences
- (void)doThreadedProcess
{
    @synchronized (self) {
        @autoreleasepool {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

            self.progressCancelled = NO; // reset our cancelled button

            NSString * newPathString = [prefs stringForKey:@"New Path"];
            NSString * oldPathString = [prefs stringForKey:@"Old Path"];

            [self.progressSpinner setUsesThreadedAnimation:YES];
            [self.progressBar setUsesThreadedAnimation:YES];
            [self.progressSpinner startAnimation:self];
            [self.progressSpinner setIndeterminate:YES];
            [self.progressBar setIndeterminate:YES];
            //[progressSpinner setDisplayedWhenStopped:NO];
            [self.progressBar startAnimation:self];

            [self.progressMsg setStringValue:@"Preparing..."];

            [[self.progressBar window] makeKeyAndOrderFront:self]; // open the progress panel

            [self.progressMsg setStringValue:@"Scanning Directory Structure"];
            NSMutableArray<NSString *> *newDirectory = [self listDirectory:newPathString];
            NSMutableArray<NSString *> *oldDirectory = [self listDirectory:oldPathString];

            [self.progressMsg setStringValue:@"Weeding Out Missing Items"];
            [self weedMissingFromArray:oldDirectory InArray:newDirectory InTitle:@"New"];
            [self weedMissingFromArray:newDirectory InArray:oldDirectory InTitle:@"Old"];

            [self compareDirectory:newPathString toDirectory:oldPathString withContents:newDirectory];

            if (self.progressCancelled == YES)
            {
                [self.logString appendString:@"*** Compare Process Cancelled by User ***\n"];
            }
            [self closeLog]; // Flush our log text out to our logfile.

            [self.progressBar stopAnimation:self];
            [self.progressSpinner stopAnimation:self];
            
            [[self.progressBar window] close]; // close the progress panel
            
            NSRunAlertPanel(@"Complete", @"Directory comparison is complete, see log for details.", @"Done", nil, nil);
        }
    }

    return;
}

- (int)comparePaths
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int result = 0;
    BOOL isDirNew = NO, isDirOld = NO;
    NSString * newPathString = [prefs stringForKey:@"New Path"];
    NSString * oldPathString = [prefs stringForKey:@"Old Path"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
//    [prefs integerForKey:@"Compare Resources"];
//    [prefs integerForKey:@"Delete Identical"];
//    [prefs integerForKey:@"Report Different"];
//    [prefs integerForKey:@"Report Identical"];
//    [prefs integerForKey:@"Report Missing"];
//    [prefs stringForKey:@"New Path"];
//    [prefs stringForKey:@"Old Path"];

    if ([fileManager fileExistsAtPath:newPathString isDirectory:&isDirNew] == NO) {
        NSRunAlertPanel(@"Path Not Found", @"The new path specified was not found.", @"Cancel", nil, nil);
        result = -10;
    }
    else if ([fileManager fileExistsAtPath:oldPathString isDirectory:&isDirOld] == NO) {
        NSRunAlertPanel(@"Path Not Found", @"The old path specified was not found.", @"Cancel", nil, nil);
        result = -11;
    }
    else {
        if (isDirNew != isDirOld) {
            NSRunAlertPanel(@"Type Conflict", @"New and Old paths are not of same type (Directory vs. File)", @"Cancel", nil, nil);
            result = -20;
        }
        else if (isDirNew == YES) { // We have directories, process them
            
            if ([self initLog]) // Where to save the log file
            {
                [NSThread detachNewThreadSelector:@selector(doThreadedProcess) toTarget:self withObject:nil]; // run our compare process thread
//                [self doThreadedProcess];
            }
        }
        else { // We have two files, process them
            result = [self compareNewFile:newPathString toOldFile:oldPathString];

            if (result > 0)
                NSRunAlertPanel(@"Equal", @"The compared files are equal.", @"Done", nil, nil);
            else
                NSRunAlertPanel(@"Not Equal", @"The compared files are not equal.", @"Done", nil, nil);
        }
    }
    return result;
}

// Creates a 40-byte checksum for a given file.  
- (NSString *)checksumForFile:(NSString *)file
{
    NSData * fileData = [NSData dataWithContentsOfFile:file];

    if (!fileData)
        return nil;

    NSMutableString * checksum_string = [[NSMutableString alloc] init];
    NSUInteger length = [fileData length];

    SHA3CTX context;
    unsigned char digest[200] = "";
    unsigned char checksumChar;
    short i = 0, j = 0;
    const void *bytes = [fileData bytes];

    SHA3Init(&context, SHA3_256);

    SHA3Update(&context, (void *)bytes, (uint32_t)length);

    SHA3Final(digest, &context);

    for (i = 0; i < 5; i++)
    {
        for (j = 0; j < 4; j++)
        {
            long location = i * 4 + j;
            NSAssert1(location >= 0 && location < 200, @"Bad location -- %ld", location);
            checksumChar = digest[location];
            [checksum_string appendFormat:@"%02X", checksumChar];
        }
    }

    return checksum_string;
}

// Compare two files for equality.  Returning > 0 means equal.
- (BOOL)compareNewFile:(NSString *)newFile toOldFile:(NSString *)oldFile
{
    BOOL isEqual = NO;

    if (!newFile || !oldFile)
        return isEqual;

    NSString *one_sum_string = [self checksumForFile:newFile];
    if (one_sum_string)
    {
        NSString *two_sum_string = [self checksumForFile:oldFile];
        if (two_sum_string)
            isEqual = [one_sum_string isEqualToString:two_sum_string];
    }

    return isEqual;
}

- (int)initLog
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString * newPathString = [prefs stringForKey:@"New Path"];
    NSString * oldPathString = [prefs stringForKey:@"Old Path"];

    NSSavePanel *sPanel = [NSSavePanel savePanel];
    [sPanel setTitle:@"Save DiffyX Results"];
    NSInteger result = [sPanel runModalForDirectory:NSHomeDirectory() file:@"diffyx-log.txt"];
    if (result == NSOKButton) {
        NSMutableString *logString = [[NSMutableString alloc] initWithString:@"*** Begin Settings ***\n"];

        [logString setString:@"*** Begin Settings ***\n"];
        [logString appendFormat:@"\tNew Directory Path: %@\n", newPathString];
        [logString appendFormat:@"\tOld Directory Path: %@\n", oldPathString];
        [logString appendFormat:@"\tCompare Resources: %@\n", @"Disabled"];
        [logString appendFormat:@"\tReport Differences: %d\n", (int)[prefs integerForKey:@"Report Different"]];
        [logString appendFormat:@"\tReport Identicals: %d\n", (int)[prefs integerForKey:@"Report Identical"]];
        [logString appendFormat:@"\tReport Missing: %d\n", (int)[prefs integerForKey:@"Report Missing"]];
        [logString appendFormat:@"\tDelete Identicals: %d\n", (int)[prefs integerForKey:@"Delete Identical"]];
        [logString appendString:@"*** End Settings ***\n"];

        _logString = logString;

        NSString *fileName = [sPanel filename];
        if (!fileName)
            fileName = @"";
        self.logFile = fileName;

        result = 1;
    }
    else
    {
        result = 0;
    }
    return (int)result;
}

- (void)closeLog
{
    NSAssert(self.logFile != NULL && self.logFile.length > 0, @"Must have a valid destination log file");
    [self.logString writeToFile:self.logFile atomically:NO];
    self.logString = [[NSMutableString alloc] init];

    NSMutableString *logFile = [self.logFile mutableCopy];
    [logFile appendString:@".next.log"];
    self.logFile = logFile;
}

@end





/*
 size_t Macfread(void *ptr, size_t size, size_t nmemb, short *refNum)
 {
     long	count, nbytes;
     short	err = -1;
     count = nbytes = nmemb * size;
     err = FSRead(*refNum, &count, ptr);
     return count;
 }
 */

/*
 // Creates an 80-byte checksum  for a given file.
 {

     errNum = FSpOpenDF ( myFSSPtr, fsRdPerm, &refNum );
     errNum = runChecksum( refNum, checksum_string, checksumResource, theSuperDialog);
     FSClose( refNum );

     refNum = FSpOpenResFile( myFSSPtr, fsRdPerm );
     errNum = runChecksum( refNum, checksum_string, checksumResource, theSuperDialog);
     CloseResFile( refNum );
 }
 */

