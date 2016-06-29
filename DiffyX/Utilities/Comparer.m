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
    _logURL = nil;
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
        NSString * fullPath = [pathString stringByAppendingPathComponent:pname];
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

    [theArray sortUsingSelector:@selector(localizedStandardCompare:)];
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
            [NSThread sleepUntilDate:[NSDate date]];
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
- (void)compareDirectory:(NSString *)fromDir
             toDirectory:(NSString *)toDir
            withContents:(NSMutableArray *)heirarchy
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    NSURL *fromDirURL = [NSURL fileURLWithPath:fromDir];
    NSURL *toDirURL = [NSURL fileURLWithPath:toDir];
    NSString *pname = nil;
    int loopCounter = 0;
    double fileCount = 0;
    double maxFiles = [heirarchy count];

    [self.progressBar setMinValue:0];
    [self.progressBar setMaxValue:maxFiles];
    [self.progressBar setIndeterminate:NO];

    NSEnumerator *iter = [heirarchy objectEnumerator];
    while ((self.progressCancelled == NO) && (pname = [iter nextObject]))
    {
        loopCounter++;
        if (loopCounter % 360 == 0) // yield some time once in a while
        {
            [NSThread sleepUntilDate:[NSDate date]];
            loopCounter = 0;
        }

        fileCount++;
        [self.progressBar setDoubleValue:fileCount];

        [self.progressMsg setStringValue:pname];

        NSURL *newFileURL = [fromDirURL URLByAppendingPathComponent:pname];
        NSURL *oldFileURL = [toDirURL URLByAppendingPathComponent:pname];

        // Compare two files for equality.  Returning > 0 means equal.
        BOOL isEqual = [self compareNewFileURL:newFileURL toOldFileURL:oldFileURL];

        if (!isEqual)
        {
            if ([prefs integerForKey:@"Report Different"])
            {
                // ********** report different files
                [self.logString appendFormat:@"Files are different: %@\n", pname];
            }
        }
        else
        {
            if ([prefs integerForKey:@"Report Identical"])
            {
                [self.logString appendFormat:@"Files are indentical: %@\n", pname];
            }

            if ([prefs integerForKey:@"Delete Identical"])
            {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error = nil;

                [fileManager removeItemAtURL:newFileURL error:&error];
                if (error)
                    [self.logString appendFormat:@"Error while attempting to delete the identical file at '%@': %@\n", newFileURL.absoluteString, error];

                [fileManager removeItemAtURL:oldFileURL error:&error];
                if (error)
                    [self.logString appendFormat:@"Error while attempting to delete the identical file at '%@': %@\n", oldFileURL.absoluteString, error];
            }
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

            self.progressMsg.stringValue = @"Preparing...";
            [[self.progressBar window] makeKeyAndOrderFront:self]; // open the progress panel

            self.progressMsg.stringValue = @"Scanning Directory Structure";
            NSMutableArray<NSString *> *newDirectory = [self listDirectory:newPathString];
            NSMutableArray<NSString *> *oldDirectory = [self listDirectory:oldPathString];

            self.progressMsg.stringValue = @"Weeding Out Missing Items";
            [self weedMissingFromArray:oldDirectory InArray:newDirectory InTitle:@"New"];
            [self weedMissingFromArray:newDirectory InArray:oldDirectory InTitle:@"Old"];

            [self compareDirectory:newPathString toDirectory:oldPathString withContents:newDirectory];

            if (self.progressCancelled == YES)
            {
                [self.logString appendString:@"*** Compare Process Cancelled by User ***\n"];
            }
            [self closeLog]; // Flush our log text out to our log.

            [self.progressBar stopAnimation:self];
            [self.progressSpinner stopAnimation:self];
            
            [[self.progressBar window] close]; // close the progress panel

            NSAlert *alert = [[NSAlert alloc] init];
            alert.alertStyle = NSInformationalAlertStyle;
            alert.messageText = @"Complete";
            alert.informativeText = @"Directory comparison is complete, see log for details.";
            [alert addButtonWithTitle:@"Done"];
            [alert runModal];
        }
    }
}

- (void)compareAndRefreshUI
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.progressCancelled = NO; // reset our cancelled button
        [self.progressSpinner setUsesThreadedAnimation:YES];
        [self.progressBar setUsesThreadedAnimation:YES];
        [self.progressSpinner startAnimation:self];
        [self.progressSpinner setIndeterminate:YES];
        [self.progressBar setIndeterminate:YES];
        [self.progressBar startAnimation:self];

        self.progressMsg.stringValue = @"Comparing...";
        [[self.progressBar window] makeKeyAndOrderFront:self]; // open the progress panel
    }];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

        NSString * newPathString = [prefs stringForKey:@"New Path"];
        NSString * oldPathString = [prefs stringForKey:@"Old Path"];

        NSMutableArray<NSString *> *newDirectory = [self listDirectory:newPathString];
        NSMutableArray<NSString *> *oldDirectory = [self listDirectory:oldPathString];

        [self weedMissingFromArray:oldDirectory InArray:newDirectory InTitle:@"New"];
        [self weedMissingFromArray:newDirectory InArray:oldDirectory InTitle:@"Old"];

        [self compareDirectory:newPathString toDirectory:oldPathString withContents:newDirectory];

        if (self.progressCancelled == YES)
            [self.logString appendString:@"*** Compare Process Cancelled by User ***\n"];

        [self closeLog]; // Flush our log text out to our log.

        [self.progressBar stopAnimation:self];
        [self.progressSpinner stopAnimation:self];

        [[self.progressBar window] close]; // close the progress panel

        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSInformationalAlertStyle;
        alert.messageText = @"Complete";
        alert.informativeText = @"Directory comparison is complete, see log for details.";
        [alert addButtonWithTitle:@"Done"];
        [alert runModal];
    }];
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
                [NSThread detachNewThreadSelector:@selector(compareAndRefreshUI) toTarget:self withObject:nil]; // run our compare process thread
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

- (NSString *)checksumForURL:(NSURL *)url
{
    NSError *error = nil;
    NSData * fileData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];

    if (!fileData || error)
    {
        NSLog(@"Error reading '%@': %@", url, error);
        return nil;
    }

    NSMutableString * checksum_string = [[NSMutableString alloc] init];
    NSUInteger length = [fileData length];

    SHA3CTX context;
    unsigned char digest[200] = "";
    unsigned char checksumChar = 0;
    short i = 0;
    short j = 0;
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

- (BOOL)compareNewFileURL:(NSURL *)newURL toOldFileURL:(NSURL *)oldURL
{
    BOOL isEqual = NO;

    if (!newURL || !oldURL)
        return isEqual;

    NSString *one_sum_string = [self checksumForURL:newURL];
    if (one_sum_string)
    {
        NSString *two_sum_string = [self checksumForURL:oldURL];
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
    sPanel.title = @"Save DiffyX Results";
    sPanel.directoryURL = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    sPanel.nameFieldStringValue = @"diffyx-log.txt";

    int result = 0;
    if ([sPanel runModal] == NSFileHandlingPanelOKButton)
    {
        NSMutableString *logString = [[NSMutableString alloc] initWithString:@"*** Begin Settings ***\n"];
        [logString appendFormat:@"\tNew Directory Path: %@\n", newPathString];
        [logString appendFormat:@"\tOld Directory Path: %@\n", oldPathString];
        [logString appendFormat:@"\tCompare Resources: %@\n", @"Disabled"];
        [logString appendFormat:@"\tReport Differences: %d\n", (int)[prefs integerForKey:@"Report Different"]];
        [logString appendFormat:@"\tReport Identicals: %d\n", (int)[prefs integerForKey:@"Report Identical"]];
        [logString appendFormat:@"\tReport Missing: %d\n", (int)[prefs integerForKey:@"Report Missing"]];
        [logString appendFormat:@"\tDelete Identicals: %d\n", (int)[prefs integerForKey:@"Delete Identical"]];
        [logString appendString:@"*** End Settings ***\n"];

        _logString = logString;
        _logURL = sPanel.URL;

        result = 1;
    }

    return result;
}

- (void)closeLog
{
    NSAssert(self.logURL != NULL, @"Must have a valid destination log file");
    NSError *error = nil;
    [self.logString writeToURL:self.logURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    self.logString = [[NSMutableString alloc] init];
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

